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
