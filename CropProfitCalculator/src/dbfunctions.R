#
# Functions that access the database
# Crop Profitability Calculator
# Author: Caitlin Ross
# Last Modified: 2022/04/10
#


# Returns the list of crops
# Arguments:
#   DB connection arguments as list
load_croplist <- function(conn_args) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Create the list of crops for the user to choose from
  crop_vector <- c(dbGetQuery(con, 
                              "SELECT NAME FROM croplist;"))
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Return the list of crops
  crop_vector
}


# Return TRUE if the location is valid, FALSE otherwise
# Arguments:
#   DB connection arguments as list,
#   Place name as character vector,
#   Province as character vector
verify_location <- function(conn_args, place, province) {
  # Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Get the result set of the query
  res_names <- c(dbGetQuery(con, 
                            str_c("SELECT DISTINCT place_names.PNname 
                                    FROM place_names 
                                    INNER JOIN province ON place_names.PRidu = province.PRcode
                                    WHERE place_names.PNname=\"", 
                                  place, 
                                  "\" AND province.PRname=\"", 
                                  province,
                                  "\";")))
  
  #Close the DB connection
  dbDisconnect(con)
  
  #Return whether the location is valid
  identical(place, str_remove_all(str_to_lower(stri_trans_nfd(str_c(res_names))), "[^a-z,A-Z]"))
}


# Returns the estimated expenses per acre
# Arguments:
#   DB connection arguments as list,
#   Province as character vector
est_exp <- function(conn_args, prov) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Get the estimated expenses per acre
  expense_res <- dbGetQuery(con,
                            str_c("SELECT (sum(exp.VALUE) / sum(land.VALUE))",
                                  " FROM operating_expenses AS exp ",
                                  "INNER JOIN census_land_use AS land ",
                                  "ON exp.GEO = land.GEO ",
                                  "WHERE exp.GEO LIKE \"%", prov, "%\" ",
                                  "AND exp.UOM=\"Dollars\" ",
                                  "AND land.LAND_USE LIKE \"Land in crops%\" ",
                                  "AND land.UOM = \"Acres\";"))
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Return the result
  expense_res
}


# Returns the estimated revenue per acre
# Arguments:
#   DB connection arguments as list,
#   Province as character vector,
#   Crop as character vector
est_rev <- function(conn_args, prov, crop) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Get the estimated yield per acre in kilograms
    
    #Get the estimated price per kilo
    
    
    #Disconnect from the database
    dbDisconnect(con)
  
  #Return the estimated revenue per acre (yield x price)
}