#
# Functions that access the database
# Crop Profitability Calculator
# Author: Caitlin Ross
# Last Modified: 2022/04/12
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


# Return the type of crop (field, fruit, or vegetable)
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
  
  # Return whether there are results in the dataset
  NROW(names_res) >= 1
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
  # Initialize revenue variable to 0
  rev_per_acre <- 0
  
  # Get the estimated revenue per acre in CAD
  # Delegates to separate functions based on type of crop
  if(crop$type == "field") {
    rev_per_acre <- est_rev_field(conn_args, loc, crop$name)
    
  } else if (crop$type == "fruit") {
    rev_per_acre <- est_rev_fruit(conn_args, loc, crop$name)
    
  } else if (crop$type == "vegetable") {
    rev_per_acre <- est_rev_veg(conn_args, loc, crop$name)
    
  } else {
    # something went very wrong, assign null value
    rev_per_acre <- NA
  }
  
  # Return the estimated revenue per acre
  rev_per_acre
}


# Returns the estimated revenue per acre of a field crop
# Arguments:
#   DB connection arguments as list object,
#   Location as list object,
#   Crop name as character vector
est_rev_field <- function(conn_args, loc, crop_name) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string for the yield
  field_yield_query <- str_c("SELECT avg(`VALUE`), UOM ",
                             "FROM est_prodval_field_crops ",
                             "WHERE HARVEST_DISPOSITION LIKE \"Average yield%\" ", 
                             "AND GEO LIKE \"", loc$province, "\" ",
                             "AND TYPE_OF_CROP LIKE \"%", crop_name,"%\" ",
                             "AND NOT `VALUE`=0 ",
                             "GROUP BY UOM;")
  
  # Query the database
  field_yield_res <- dbGetQuery(con, field_yield_query)
  
  # Retrieve the yield in kilograms per hectare
  # Convert to kg per acre
  field_yield <- first(filter(field_yield_res,
                                         UOM == 'Kilograms per hectare'))
  
  # Build the query string for the value
  field_val_query <- str_c("SELECT avg(`VALUE`), GEO, FARM_PRODUCTS, UOM ",
                           "FROM farm_product_prices ",
                           "WHERE GEO LIKE \"%", loc$province, "%\" ",
                           "AND FARM_PRODUCTS LIKE \"%", crop_name, "%\" ",
                           "AND NOT `VALUE`=0 ",
                           "GROUP BY UOM;")
  
  # Query the database
  field_val_res <- dbGetQuery(con, field_val_query)
  
  # Retrieve the dollar value per metric tonne
  # Covert to CAD per kilogram
  field_value <- first(filter(field_val_res,
                              UOM == 'Dollars per metric tonne'))
  
  # Disconnect from the database
  dbDisconnect(con)
  
  # If the value query returned nothing, set to 0
  if(is.null(field_value) || is.null(field_yield)) {
    field_rev <- 0.0
  } else {
    # Multiply the value ($/kg) by the yield (kg/acre) to get revenue ($/acre)
    field_rev <- 0.001 * field_value * 0.404686 * field_yield
  }
  
  field_rev
}


# Returns the estimated revenue per acre of a fruit crop
# Arguments:
#   DB connection arguments as list object,
#   Location as list object,
#   Crop name as character vector
est_rev_fruit <- function(conn_args, loc, crop_name) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string
  fruit_query <- str_c("SELECT avg(`VALUE`), ESTIMATES, UOM ",
                       "FROM prodval_marketed_fruits ",
                       "WHERE GEO LIKE \"%", loc$province, "%\" ",
                       "AND COMMODITY LIKE \"%", crop_name, "%\" ",
                       "AND NOT `VALUE`=0 ",
                       "GROUP BY ESTIMATES;")
  
  # Query the database
  fruit_res <- dbGetQuery(con, fruit_query)
  
  # Disconnect from the database
  dbDisconnect(con)
  
  # Retrieve the total area planted
  fruit_area <- first(filter(fruit_res,
                             ESTIMATES == 'Cultivated area, total'))
  
  # Retrieve the total farm gate value
  fruit_value <- first(filter(fruit_res,
                              ESTIMATES == 'Farm gate value'))
  
  # Prevent dividing by 0
  if(fruit_area == 0 || is.null(fruit_value)) {
    fruit_rev <- 0
    
  } else {
    # Return Farm Gate Value (in 1000s of dollars) * 1000 / Cultivated Area
    fruit_rev <- (fruit_value  * 1000) / fruit_area
  }
  
  fruit_rev
}


# Returns the estimated revenue per acre of a vegetable crop
# Arguments:
#   DB connection arguments as list object,
#   Location as list object,
#   Crop name as character vector
est_rev_veg <- function(conn_args, loc, crop_name) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  # Build the query string
  veg_query <- str_c("SELECT avg(`VALUE`), ESTIMATES, UOM ",
                       "FROM prodval_marketed_veg ",
                       "WHERE GEO LIKE \"%", loc$province, "%\" ",
                       "AND COMMODITY LIKE \"%", crop_name, "%\" ",
                       "AND NOT `VALUE`=0 ",
                       "GROUP BY ESTIMATES;")
  
  # Query the database
  veg_res <- dbGetQuery(con, veg_query)
  
  # Disconnect from the database
  dbDisconnect(con)
  
  # Retrieve the total area planted
  veg_area <- first(filter(veg_res,
                             ESTIMATES == 'Area planted (acres)'))
  
  # Retrieve the total farm gate value
  veg_value <- first(filter(veg_res,
                              ESTIMATES == 'Farm gate value (dollars)'))
  
  # Prevent dividing by 0
  if(veg_area == 0 || is.null(veg_value)) {
    veg_rev <- 0
  } else {
    # Return Farm Gate Value (in 1000s of dollars) * 1000 / Cultivated Area
    veg_rev <- (veg_value  * 1000) / veg_area
  }
  
  veg_rev
}