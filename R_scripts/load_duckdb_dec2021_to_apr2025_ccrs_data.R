# ============================================================
# Evergreen Canna Ledger - DuckDB Master Data Loader
# ------------------------------------------------------------
# This script registers Parquet datasets (master + monthly)
# into DuckDB, creates unified "_all" views, and prepares
# the environment for downstream analytics and dashboards.
# ============================================================

library(tidyverse)
library(DBI)
library(dplyr)
library(lubridate)
library(plotly)
library(arrow)
library(duckdb)
library(fs)
library(glue)

# ------------------------------------------------------------
# Utility Functions
# ------------------------------------------------------------

# Clean Slate: Unregister all active Arrow datasets
unregister_all_arrow <- function(con) {
  walk(duckdb_list_arrow(con), ~ {
    duckdb_unregister_arrow(con, .x)
    message("🧹 Unregistered: ", .x)
  })
}

# Snake Case Column Helper
to_snake <- function(x) {
  x %>%
    tools::file_path_sans_ext() %>%
    str_replace_all("([a-z])([A-Z])", "\\1_\\2") %>%
    str_replace_all("[^[:alnum:]_]", "_") %>%
    str_to_lower()
}

# ------------------------------------------------------------
# Database Paths and Connection
# ------------------------------------------------------------
base_dir <- "C:/Users/theob/OneDrive/Documents/parquet_cannabis_master/arrow"
duckdb_path <- file.path(dirname(base_dir), "duckdb_master.duckdb")

# Connect
con <- dbConnect(duckdb::duckdb(), dbdir = duckdb_path, read_only = FALSE)

# ------------------------------------------------------------
# Register Master Parquet Tables
# ------------------------------------------------------------
register_master_parquet <- function(con, base_dir) {
  master_files <- list.files(base_dir, pattern = "\\.parquet$", full.names = TRUE)
  
  table_names <- tools::file_path_sans_ext(basename(master_files)) %>%
    str_replace_all("([a-z])([A-Z])", "\\1_\\2") %>%
    str_replace_all("[^[:alnum:]_]", "_") %>%
    str_to_lower()
  
  walk2(table_names, master_files, ~ {
    table_name <- paste0(.x, "_master")
    if (table_name %in% duckdb_list_arrow(con)) {
      duckdb_unregister_arrow(con, table_name)
      message("🧹 Unregistered master: ", table_name)
    }
    
    dataset <- arrow::open_dataset(.y)
    duckdb_register_arrow(con, table_name, dataset)
    message("📦 Registered master: ", table_name)
  })
}

register_master_parquet(con, base_dir)

# ------------------------------------------------------------
# Register Monthly Arrow Folders
# ------------------------------------------------------------
register_monthly_parquet_to_duckdb <- function(db_path, parquet_folders) {
  con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)
  
  for (folder in parquet_folders) {
    month_label <- basename(folder)
    parquet_files <- list.files(folder, pattern = "\\.parquet$", full.names = TRUE)
    
    table_names <- tools::file_path_sans_ext(basename(parquet_files)) %>%
      str_replace_all("([a-z])([A-Z])", "\\1_\\2") %>%
      str_replace_all("[^[:alnum:]_]", "_") %>%
      str_to_lower()
    
    walk2(table_names, parquet_files, ~ {
      table_name <- paste0(.x, "_", month_label)
      if (table_name %in% duckdb_list_arrow(con)) {
        duckdb_unregister_arrow(con, table_name)
        message("🧹 Unregistered: ", table_name)
      }
      
      dataset <- arrow::open_dataset(.y)
      duckdb_register_arrow(con, table_name, dataset)
      message("📌 Registered monthly: ", table_name)
    })
  }
  
  return(con)
}

monthly_dirs <- dir_ls(base_dir, recurse = FALSE, type = "directory")
monthly_arrow_dirs <- monthly_dirs[str_detect(monthly_dirs, "arrow_[a-z]+2025")]
register_monthly_parquet_to_duckdb(duckdb_path, monthly_arrow_dirs)

# ------------------------------------------------------------
# Create Combined Views
# ------------------------------------------------------------
create_combined_view <- function(con, base_name) {
  tables <- duckdb_list_arrow(con)
  relevant_tables <- tables[str_detect(tables, paste0("^", base_name, "_(master|arrow_.*2025)"))]
  
  if (length(relevant_tables) == 0) {
    message("⚠️ No tables found for ", base_name)
    return(invisible(NULL))
  }
  
  column_lists <- map(relevant_tables, ~ {
    cols <- names(dbGetQuery(con, glue("SELECT * FROM \"{.x}\" LIMIT 0")))
    tibble(table = .x, column = cols)
  }) %>% bind_rows()
  
  common_columns <- column_lists %>%
    group_by(column) %>%
    summarise(n_tables = n_distinct(table), .groups = "drop") %>%
    filter(n_tables == length(relevant_tables)) %>%
    pull(column)
  
  if (length(common_columns) == 0) {
    message("❌ No common columns found across tables for ", base_name)
    return(invisible(NULL))
  }
  
  dropped_cols <- setdiff(unique(column_lists$column), common_columns)
  if (length(dropped_cols)) {
    message("⚠️ Dropping columns not in all tables for ", base_name, ": ", paste(dropped_cols, collapse = ", "))
  }
  
  union_parts <- map_chr(relevant_tables, ~ {
    cols <- paste(common_columns, collapse = ", ")
    glue("SELECT {cols} FROM \"{.x}\"")
  })
  
  union_sql <- glue("
    CREATE OR REPLACE VIEW {base_name}_all AS
    {paste(union_parts, collapse = '\nUNION ALL\n')}
  ")
  
  dbExecute(con, union_sql)
  message("✅ Created view: ", base_name, "_all with ", length(relevant_tables), " parts.")
}

views_to_create <- c("sales_detail", "sale_header", "inventory", "product",
                     "areas", "licensee", "plant", "strains", "contacts")

walk(views_to_create, ~ create_combined_view(con, .x))

message("✅ All views created and ready for analysis.")
