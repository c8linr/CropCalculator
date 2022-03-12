#
# Back end of the Crop Profitability Calculator
# Author: Caitlin Ross
#

if (!require("pacman")) install.packages("pacman")
pacman::p_load(pacman, shiny, DBI, RMariaDB, tidyverse)

# Define server logic required to calculate profitability
shinyServer(function(input, output, session) {
  #Connect to the database
  con <- dbConnect(RMariaDB::MariaDB(), default.file='..\\.my.cnf', group='rs-dbi', dbname='cropdata')
  
  #Create the list of crops for the user to choose from
  crop_vector <- c(dbGetQuery(con, "SELECT crop FROM cropdata.crop_list;"))
  
  #Update the crop selection widget
  updateSelectInput(session, "crop", choices = crop_vector)
  
  #Get the list of valid locations
  canada_places <- c(dbGetQuery(con, "SELECT DISTINCT PNname FROM cropdata.place_names;"))
  
  #Validate the location
  output$calculation <- eventReactive(input$calculate, {
      valid_location <- FALSE
      for(place in canada_places) {
        compare_places <- identical(tolower(input$location), tolower(place))
        if(compare_places) {
          valid_location = TRUE
        }
      }
      shinyFeedback::feedbackWarning("location", !valid_location, "Invalid location")
      req(valid_location)
      calculation <- str_c("The estimated profitability for ", input$crop, " in ", str_to_title(input$location), " is $X")
    })
  
  #Update the output
  
  
  # output$calculation <- reactive({
  #   #Validate the location
  #   is_valid_location <- FALSE
  #   for(place in canada_places) {
  #     compare_places <- identical(tolower(input$location), tolower(place))
  #     if(compare_places) {
  #       is_valid_location = TRUE
  #     }
  #   }
  #   shinyFeedback::feedbackWarning("location", !is_valid_location, "Invalid location")
  #   calculation <- str_c("The estimated profitability for ", input$crop, " in ", input$location, " is $X")
  # })
  
  #Disconnect from the database
  dbDisconnect(con)
})