# connect_duckdb_readonly.R

library(DBI)
library(duckdb)
library(purrr)
library(stringr)

duckdb_path <- here::here("duckdb_combined.duckdb")

# Open in read-only mode to avoid file locking or write errors
con <- dbConnect(duckdb::duckdb(), dbdir = duckdb_path, read_only = FALSE)

clean_rules <- list(
  
  Product_all = "
  WHERE 
    (TRY_CAST(CreatedDate AS TIMESTAMP) IS NOT NULL) AND
    (TRY_CAST(ProductId AS BIGINT) IS NOT NULL) AND
    (TRY_CAST(LicenseeId AS BIGINT) IS NOT NULL) AND
    NOT regexp_matches(CAST(CreatedDate AS VARCHAR), '[a-zA-Z]')"
    
  # WHERE 
  # (IsDeleted IS NULL OR UPPER(IsDeleted) != 'TRUE') AND
  # TRY_CAST(CreatedDate AS TIMESTAMP) IS NOT NULL AND
  # regexp_matches(CAST(CreatedDate AS VARCHAR), '^[0-9]{4}-[0-9]{2}-[0-9]{2}( [0-9]{2}:[0-9]{2}(:[0-9]{2})?)?$') AND
  # TRY_CAST(ProductId AS BIGINT) IS NOT NULL AND
  # TRY_CAST(LicenseeId AS BIGINT) IS NOT NULL
,
  
  SalesDetail_all = "
    WHERE 
      (IsDeleted IS NULL OR UPPER(IsDeleted) != 'TRUE') AND
      TRY_CAST(SaleDetailId AS BIGINT) IS NOT NULL AND
      TRY_CAST(CreatedDate AS TIMESTAMP) IS NOT NULL
  ",
  
  Licensee_all = "
    WHERE 
      (IsDeleted IS NULL OR UPPER(IsDeleted) != 'TRUE') AND
      TRY_CAST(LicenseeId AS BIGINT) IS NOT NULL
  ",
  
  Plant_all = "
    WHERE 
      (IsDeleted IS NULL OR UPPER(IsDeleted) != 'TRUE') AND
      TRY_CAST(CreatedDate AS TIMESTAMP) IS NOT NULL
  ",
  
  ManifestHeader_all = "
  WHERE 
    (IsDeleted IS NULL OR UPPER(IsDeleted) != 'TRUE') AND
    TRY_CAST(CCRSManifestHeaderId AS BIGINT) IS NOT NULL AND
    TRY_CAST(ManifestGeneratedDate AS TIMESTAMP) IS NOT NULL
"
  
  
  # Add others as needed...
)

clean_rules$Product_all <- "
  WHERE 
    (TRY_CAST(CreatedDate AS TIMESTAMP) IS NOT NULL) AND
    (TRY_CAST(ProductId AS BIGINT) IS NOT NULL) AND
    (TRY_CAST(LicenseeId AS BIGINT) IS NOT NULL) AND
    NOT regexp_matches(CAST(CreatedDate AS VARCHAR), '[a-zA-Z]')
"

create_clean_views <- function(con, rules) {
  walk(names(rules), function(table_name) {
    clean_sql <- glue::glue("
      CREATE OR REPLACE VIEW {str_replace(table_name, '_all', '_clean')} AS
      SELECT DISTINCT * FROM {table_name}
      {rules[[table_name]]}
    ")
    DBI::dbExecute(con, clean_sql)
    message("✅ Created clean view for: ", table_name)
  })
}

create_clean_views(con, clean_rules)

dbDisconnect(con)

con <- dbConnect(duckdb::duckdb(), dbdir = duckdb_path, read_only = TRUE)