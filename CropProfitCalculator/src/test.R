# #Ensure required packages are present
# if (!require("pacman")) install.packages("pacman")
# pacman::p_load(pacman, shiny, DBI, RMariaDB, tidyverse)
# 
# #Connect to the database
# con <- dbConnect(RMariaDB::MariaDB(), default.file='.my.cnf', group='rs-dbi', dbname='cropdata')
# 
# #Get the list of valid locations
# canada_places <- c(dbGetQuery(con, "SELECT DISTINCT PNname FROM cropdata.place_names;"))
# 
# canada_places
# 
# test_location <- "ottawa"
# 
# #Validate the location
# valid_location <- FALSE
# for(place in canada_places) {
#   compare_places <- identical(c(tolower(test_location)), c(tolower(place)))
#   if(compare_places) {
#     valid_location <- TRUE
#     str_c("Comparing ", tolower(test_location), " to ", tolower(place), ": ", identical(c(tolower("ajax")), c(tolower(place))))
#   }
# }
# 
# query <- str_c("SELECT DISTINCT PNname FROM cropdata.place_names WHERE PNname=\"", str_to_lower(test_location), "\";")
# res <- c(dbGetQuery(con, query))
# identical(c(tolower(test_location)), c(tolower(res)))

#Returns the properly capitalized province name, in case the user inputted a partial name or code
# prov_name_clean <- function(prov_input) {
#   #Decompose the string to remove accents or diacritics,
#   #Make everything lower case,
#   #Remove all non-letter characters
#   clean_input <- str_remove_all(str_to_lower(stri_trans_nfd(prov_input)), "[^a-z,A-Z]")
#   
#   #Assign province names to variables to simplify the switch statement
#   NL <- "Newfoundland and Labrador"
#   PE <- "Prince Edward Island"
#   NS <- "Nova Scotia"
#   NB <- "New Brunswick"
#   QC <- "Quebec"
#   ON <- "Ontario"
#   MB <- "Manitoba"
#   SK <- "Saskatchewan"
#   AB <- "Alberta"
#   BC <- "British Columbia"
#   YT <- "Yukon"
#   NT <- "Northwest Territories"
#   NU <- "Nunavut"
#   
#   switch(clean_input,
#          "newfoundland" = NL,
#          "labrador" = NL,
#          "newfoundlandlabrador" = NL,
#          "newfoundlandandlabrador" = NL,
#          "nl" = NL,
#          "nfld" = NL,
#          "lab" = NL,
#          "nf" = NL,
#          "lb" = NL,
#          "terreneuve" = NL,
#          "tnl" = NL,
#          "tn" = NL,
#          "princeedwardisland" = PE,
#          "pei" = PE,
#          "pe" = PE,
#          "ileduprinceedouard" = PE,
#          "ileduprinceedward" = PE,
#          "ipe" = PE,
#          "novescotia" = NS,
#          "ns" = NS,
#          "nouvelleecosse" = NS,
#          "ne" = NS,
#          "newbrunswick" = NB,
#          "nb" = NB,
#          "nouveaubrunswick" = NB,
#          "quebec" = QC,
#          "qc" = QC,
#          "que" = QC,
#          "pq" = QC,
#          "provincedequebec" = QC,
#          "qb" = QC,
#          "ontario" = ON,
#          "on" = ON,
#          "ont" = ON,
#          "manitoba" = MB,
#          "mb" = MB,
#          "man" = MB,
#          "saskatchewan" = SK,
#          "sk" = SK,
#          "sask" = SK,
#          "alberta" = AB,
#          "ab" = AB,
#          "alta" = AB,
#          "alb" = AB,
#          "britishcolumbia" = BC,
#          "bc" = BC,
#          "colombiebritannique" = BC,
#          "cb" = BC,
#          "yukon" = YT,
#          "yukonterritory" = YT,
#          "yt" = YT,
#          "yk" = YT,
#          "yn" = YT,
#          "yuk" = YT,
#          "northwestterritories" = NT,
#          "northwest" = NT,
#          "nt" = NT,
#          "nwt" = NT,
#          "territoiresdunordoest" = NT,
#          "tno" = NT,
#          "nunavut" = NU,
#          "nu" = NU,
#          "nvt" = NU,
#          "nv" = NU,
#          "Invalid Province")
# }

# loc <- list(place="Toronto", province="Ontario")
# crop <- list(name="apple", type="fruit")
# 
# conn_args <- config::get('dataconnection')
# con <- dbConnect(odbc::odbc(),
#                  Driver = conn_args$driver,
#                  Server = conn_args$server,
#                  UID = conn_args$uid,
#                  PWD = conn_args$pwd,
#                  Port = conn_args$port,
#                  Database = conn_args$database)
# 
# # Build the query string
# fruit_query <- str_c("SELECT avg(`VALUE`), ESTIMATES, UOM ",
#                      "FROM prodval_marketed_fruits ",
#                      "WHERE GEO LIKE \"%", loc$province, "%\" ",
#                      "AND COMMODITY LIKE \"%", crop$name, "%\" ",
#                      "AND NOT `VALUE`=0 ",
#                      "GROUP BY ESTIMATES;")
# 
# # Query the database
# fruit_res <- dbGetQuery(con, fruit_query)
# dbDisconnect(con)
# fruit_res
# 
# # Retrieve the total area planted
# total_area <- first(filter(fruit_res, ESTIMATES == 'Cultivated area, total'))
# total_area
# 
# # Retrieve the total farm gate value
# total_value <- first(filter(fruit_res, ESTIMATES == 'Farm gate value'))
# total_value
# 
# revenue <- total_value / total_area
# revenue
conn_args <- config::get('dataconnection')
loc <- list(place="Toronto", province="Ontario")
crop_name <- "soy"

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
field_yield <- 0.404686 * first(filter(field_yield_res,
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
field_value <- 0.001 * first(filter(field_val_res,
                                    UOM == 'Dollars per metric tonne'))

# Multiply the value ($/kg) by the yield (kg/acre) to get revenue ($/acre)
field_rev <- field_value * field_yield

# Disconnect from the database
dbDisconnect(con)

field_rev
