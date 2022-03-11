#
# Back end of the Crop Profitability Calculator
# Author: Caitlin Ross
#

if (!require("pacman")) install.packages("pacman")
pacman::p_load(pacman, DBI, shiny, RMariaDB, tidyverse)

# Define server logic required to calculate profitability
shinyServer(function(input, output, session) {
  #Connect to the database
  con <- dbConnect(RMariaDB::MariaDB(), default.file='..\\.my.cnf', group='rs-dbi', dbname='cropdata')
  
  #Create the list of crops for the user to choose from
  crop_vector <- c(dbGetQuery(con, "SELECT DISTINCT CROP FROM cropdata.canadian_crop_yields;"))
  crop_vector <- c(crop_vector, dbGetQuery(con, "SELECT DISTINCT `Type of crop` FROM cropdata.est_prodval_field_crops;"))
  crop_vector <- c(crop_vector, dbGetQuery(con, "SELECT DISTINCT Commodity FROM cropdata.prodval_marketed_veg;"))
  crop_vector <- c(crop_vector, dbGetQuery(con, "SELECT DISTINCT Commodity FROM cropdata.prodval_marketed_fruits;"))
  crop_vector <- c(crop_vector, dbGetQuery(con, "SELECT DISTINCT Commodity FROM cropdata.prodval_greenhouse_fruit_veg;"))
  crop_vector <- c(crop_vector, dbGetQuery(con, "SELECT DISTINCT CmdtyEn_PrdtAn FROM cropdata.weekly_wholesale_product_prices;"))
  
  #Tidy list of crops that the user can choose from
  for(crop in crop_vector) {
    crop %>% str_to_lower()
    str_remove_all(crop, "[:digit:]+")
  }
  
  #Update the crop selection widget
  updateSelectInput(session, "crop", choices = crop_vector)
  
  #Disconnect from the database
  dbDisconnect(con)
})