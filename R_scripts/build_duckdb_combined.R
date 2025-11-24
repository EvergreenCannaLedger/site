# =============================================================
# Evergreen Canna Ledger - Build Combined DuckDB
# Combines all parquet data (2021–2025) into a unified DB
# =============================================================

library(DBI)
library(duckdb)
library(arrow)
library(tidyverse)
library(fs)
library(glue)

# -------------------------------------------------------------
# Paths
# -------------------------------------------------------------
project_dir <- here::here()  # should resolve to evergreen-canna-ledger
arrow_base   <- file.path(project_dir, "arrow")
duckdb_path  <- file.path(project_dir, "duckdb_combined.duckdb")

# If existing DB, remove it
if (file.exists(duckdb_path)) {
  file.remove(duckdb_path)
  message("🧹 Old DuckDB removed.")
}

# Connect (write mode)
con <- dbConnect(duckdb::duckdb(), dbdir = duckdb_path, read_only = FALSE)

# -------------------------------------------------------------
# Helper: Persist all Parquet datasets into DuckDB tables
# -------------------------------------------------------------
register_and_persist_datasets <- function(con, folders) {
  for (folder in folders) {
    label <- basename(folder)
    
    parquet_files <- dir_ls(folder, regexp = "\\.parquet$", recurse = FALSE)
    table_names   <- tools::file_path_sans_ext(basename(parquet_files))
    
    walk2(table_names, parquet_files, function(tbl_name, parquet_file) {
      full_table_name <- paste0(tbl_name, "_", label)
      
      # Open dataset
      dataset <- arrow::open_dataset(parquet_file)
      
      # Persist permanently inside DuckDB
      dbExecute(con, glue('DROP TABLE IF EXISTS "{full_table_name}"'))
      dbExecute(
        con,
        glue('CREATE TABLE "{full_table_name}" AS SELECT * FROM read_parquet(\'{parquet_file}\')')
      )
      
      message("📦 Persisted table: ", full_table_name)
    })
  }
}

# -------------------------------------------------------------
# Find all Arrow folders & persist data
# -------------------------------------------------------------
all_arrow_dirs <- dir_ls(arrow_base, type = "directory")
register_and_persist_datasets(con, all_arrow_dirs)

# -------------------------------------------------------------
# Create unified "_all" views
# -------------------------------------------------------------
create_combined_view <- function(con, base_name) {
  tables <- dbListTables(con)
  relevant_tables <- tables[str_detect(tables, paste0("^", base_name, "_"))]
  
  if (length(relevant_tables) == 0) {
    message("⚠️ No tables found for ", base_name)
    return(invisible(NULL))
  }
  
  # find common columns
  column_lists <- map(relevant_tables, ~ {
    cols <- names(dbGetQuery(con, glue("SELECT * FROM \"{.x}\" LIMIT 0")))
    tibble(table = .x, column = cols)
  }) |> bind_rows()
  
  common_cols <- column_lists |>
    group_by(column) |>
    summarise(n_tables = n_distinct(table), .groups = "drop") |>
    filter(n_tables == length(relevant_tables)) |>
    pull(column)
  
  if (length(common_cols) == 0) {
    message("❌ No common columns found for ", base_name)
    return(invisible(NULL))
  }
  
  union_parts <- map_chr(relevant_tables, ~ {
    cols <- paste(common_cols, collapse = ", ")
    glue("SELECT {cols} FROM \"{.x}\"")
  })
  
  union_sql <- glue("
    CREATE OR REPLACE VIEW {base_name}_all AS
    {paste(union_parts, collapse = '\nUNION ALL\n')}
  ")
  
  dbExecute(con, union_sql)
  message("✅ Created view: ", base_name, "_all with ", length(relevant_tables), " parts.")
}

# Full list of views
views_to_create <- c(
    "Areas", "Contacts", "Integrator", "Inventory", "InventoryAdjustment",
    "InventoryPlantTransfer", "LabResult", "Licensee", "ManifestHeader",
    "Plant", "PlantDestructions", "Product", "SaleHeader", "SalesDetail",
    "Strains", "TransportedItems"
  )

# Prior views to create list
# c(
#   "SalesDetail", "SaleHeader", "Inventory", "Product",
#   "Licensee", "Areas", "Plant", "Strains", "Contacts"
# )

walk(views_to_create, ~ create_combined_view(con, .x))

# -------------------------------------------------------------
# Wrap‑up
# -------------------------------------------------------------
message("🏁 DuckDB combined database is ready at: ", duckdb_path)
dbDisconnect(con, shutdown = TRUE)
