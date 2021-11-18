# --- Header -------------------------------------------------------------------
# See LICENSE file for details 
#
# This code pulls data from WRDS 
# ------------------------------------------------------------------------------

library(RPostgres)
library(DBI)

if (!exists("cfg")) source("code/R/read_config.R")

save_wrds_data <- function(df, fname) {
  if(file.exists(fname)) {
    file.rename(
      fname,
      paste0(
        substr(fname, 1, nchar(fname) - 4), 
        "_",
        format(file.info(fname)$mtime, "%Y-%m-%d_%H_%M_%S"),".rds")
    )
  }
  saveRDS(df, fname)
}

# --- Connect to WRDS ----------------------------------------------------------

wrds <- dbConnect(
  Postgres(),
  host = 'wrds-pgdata.wharton.upenn.edu',
  port = 9737,
  user = cfg$wrds_user,
  password = cfg$wrds_pwd,
  sslmode = 'require',
  dbname = 'wrds'
)

message("Logged on to WRDS ...")

# --- Specify filters and variables --------------------------------------------

if (FALSE) {
  # The code below can be used to inform yourself about tables and their
  # contents that are available on WRDS.
  res <- dbSendQuery(
    wrds, "select distinct table_name
  from information_schema.columns
  where table_schema='audit'
  order by table_name"
  )
  tables <- dbFetch(res, n=-1)
  dbClearResult(res)
  
  res <- dbSendQuery(wrds, "select column_name
                   from information_schema.columns
                   where table_schema='audit'
                   and table_name='feed70_europe_cblock'
                   order by column_name")
  cols <- dbFetch(res, n=-1)
  dbClearResult(res)
}



# --- Pull Audit Analytics data ------------------------------------------------

message("Pulling European Audit fee data ... ", appendLF = FALSE)
res <- dbSendQuery(wrds, "select * from audit.feed70_europe_cblock")
cblock_data <- dbFetch(res, n=-1)
dbClearResult(res)

res <- dbSendQuery(wrds, "select * from audit.feed71_eu_audit_fee")
afee_data <- dbFetch(res, n=-1)
dbClearResult(res)
message("done!")

saveRDS(cblock_data, "data/pulled/audit_analytics_cblock_data.rds")
saveRDS(afee_data, "data/pulled/audit_analytics_afee_data.rds")

dbDisconnect(wrds)
message("Disconnected from WRDS")
