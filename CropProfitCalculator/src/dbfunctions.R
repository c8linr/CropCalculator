#
# Functions that access the database
# Crop Profitability Calculator
# Author: Caitlin Ross
# Last Modified: 2022/04/10
#


# Returns the list of crops
# Arguments:
#   DB connection arguments as list object
load_croplist <- function(conn_args) {
  # Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string
  query <- str_c("SELECT NAME FROM croplist;")
  
  # Query the database
  crops_res <- c(dbGetQuery(con, query))
  
  # Disconnect from the database
  dbDisconnect(con)
  
  # Return the list of crops
  crops_res
}


# Return the type of crop (field, fruit, vegetable, or greenhouse)
# Arguments:
#   DB connection arguments as list object,
#   Name of the crop as character vector
get_crop_type <- function(conn_args, crop_name) {
  # Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string
  query <- str_c("SELECT `TYPE` ",
                 "FROM croplist ",
                 "WHERE `NAME`=\"", crop_name, "\";")
  
  # Query the database
  crop_type <- str_c(dbGetQuery(con, query))
  
  # Close the DB connection
  dbDisconnect(con)
  
  # Return the crop type
  crop_type
}


# Return TRUE if the location is valid, FALSE otherwise
# Arguments:
#   DB connection arguments as list object,
#   Location as list
verify_location <- function(conn_args, loc) {
  # Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string
  query <- str_c("SELECT DISTINCT place_names.PNname ",
                 "FROM place_names ",
                 "INNER JOIN province ",
                 "ON place_names.PRidu = province.PRcode ",
                 "WHERE place_names.PNname=\"", loc$place, 
                 "\" AND province.PRname=\"", loc$province, "\";")
  
  # Query the database 
  names_res <- c(dbGetQuery(con, query))
  
  # Close the DB connection
  dbDisconnect(con)
  
  # Return whether the location is valid
  identical(loc$place, str_remove_all(str_to_lower(stri_trans_nfd(str_c(names_res))), "[^a-z,A-Z]"))
}


# Returns the estimated expenses per acre
# Arguments:
#   DB connection arguments as list object,
#   Location as list object
est_exp <- function(conn_args, loc) {
  # Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string
  query <- str_c("SELECT (sum(exp.VALUE) / sum(land.VALUE)) ",
                 "FROM operating_expenses AS exp ",
                 "INNER JOIN census_land_use AS land ",
                 "ON exp.GEO = land.GEO ",
                 "WHERE exp.GEO LIKE \"%", loc$province, "%\" ",
                 "AND exp.UOM=\"Dollars\" ",
                 "AND land.LAND_USE LIKE \"Land in crops%\" ",
                 "AND land.UOM = \"Acres\";")
  
  # Query the database
  expense_res <- dbGetQuery(con, query)
  
  # Disconnect from the database
  dbDisconnect(con)
  
  # Return the estimated expense
  expense_res
}


# Returns the estimated revenue per acre
# Arguments:
#   DB connection arguments as list object,
#   Location as list object,
#   Crop as list object
est_rev <- function(conn_args, loc, crop) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Initialize revenue variable to 0
  rev_per_acre <- 0
  
  # Get the estimated revenue per acre in CAD
  if(crop$type == "field") {
    # Build the query string for the yield
    field_yield_query <- str_c("SELECT avg(prod.VALUE), prod.UOM ",
                   "FROM est_prodval_field_crops AS prod ",
                   "WHERE prod.HARVEST_DISPOSITION LIKE \"Average yield%\" ", 
                   "AND prod.GEO LIKE \"", loc$province, "\" ",
                   "AND prod.TYPE_OF_CROP LIKE \"%", crop$name,"%\" ",
                   "AND NOT prod.VALUE=0 ",
                   "GROUP BY prod.UOM;")
    
    # Query the database
    field_yield_res <- dbGetQuery(con, field_yield_query)
    
    # Build the query string for the value
    #field_val_query <- str_c("")
    
    # Query the database
    #field_val_res <- dbGetQuery(con, field_val_query)
    
    # TODO: Get the relevant value from the data frame
    
  } else if (crop$type == "fruit") {
    # Build the query string
    fruit_query <- str_c("SELECT avg(`VALUE`), ESTIMATES, UOM ",
                         "FROM prodval_marketed_fruits ",
                         "WHERE GEO LIKE \"", loc$province, "\"",
                         "AND COMMODITY LIKE \"", crop$name, "\"",
                         "AND NOT `VALUE`=0",
                         "GROUP BY ESTIMATES;")
    
    # Query the database
    fruit_res <- dbGetQuery(con, fruit_query)
    
    # TODO: get the relevant value from the data frame
    
  } else if (crop$type == "vegetable") {
    # Build the query string
    veg_query <- str_c("SELECT avg(`VALUE`), ESTIMATES, UOM ",
                         "FROM prodval_marketed_veg ",
                         "WHERE GEO LIKE \"", loc$province, "\"",
                         "AND COMMODITY LIKE \"", crop$name, "\"",
                         "AND NOT `VALUE`=0",
                         "GROUP BY ESTIMATES;")
    
    # Query the database
    veg_res <- dbGetQuery(con, veg_query)
    
    # TODO: get the relevant value from the data frame
    
  } else if (crop$type == "greenhouse") {
    # Build the query string
    gh_query <- str_c("SELECT avg(`VALUE`), PRODUCTION_AND_VALUE, UOM ",
                       "FROM prodval_greenhouse_fruit_veg ",
                       "WHERE GEO LIKE \"", loc$province, "\"",
                       "AND COMMODITY LIKE \"", crop$name, "\"",
                       "AND NOT `VALUE`=0",
                       "GROUP BY PRODUCTION_AND_VALUE, UOM;")
    
    # Query the database
    gh_res <- dbGetQuery(con, gh_query)
    
    # TODO: get the relevant value from the data frame
    
  } else {
    # something went very wrong, return invalid number
    rev_per_acre <- NA
  }
  
  # Disconnect from the database
  dbDisconnect(con)
  
  # Return the estimated revenue per acre (yield x price)
  rev_per_acre
}