#
# Back end of the Crop Profitability Calculator
# Author: Caitlin Ross
#

library(shiny)
library(DBI)
library(config)
library(tidyverse)

# Define server logic required to calculate profitability
shinyServer(function(input, output, session) {
  
  #Load different config parameters depending on whether I'm running the local or remote instance
  conn_args <- config::get('dataconnection')
  
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Create the list of crops for the user to choose from
  crop_vector <- c(dbGetQuery(con, "SELECT crop FROM crop_list;"))
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Update the crop selection widget
  updateSelectInput(session, "crop", choices = crop_vector)
  
  #Validate the location when the submit button is pressed
  output$calculation <- eventReactive(input$calculate, {
    # Connect to the database IN SCOPE
    con2 <- dbConnect(odbc::odbc(),
                      Driver = conn_args$driver,
                      Server = conn_args$server,
                      UID = conn_args$uid,
                      PWD = conn_args$pwd,
                      Port = conn_args$port,
                      Database = conn_args$database)
    
    # Construct the query string
    query_names <- str_c("SELECT DISTINCT PNname FROM place_names WHERE PNname=\"", str_to_lower(input$location), "\";")
    
    #Get the result set of the query
    res_names <- c(dbGetQuery(con2, query_names))
    
    #Determine if the location is valid
    valid_location <- identical(c(str_to_lower(input$location)), c(tolower(res_names)))
    
    #Display a warning if the location is invalid
    shinyFeedback::feedbackWarning("location", !valid_location, "Invalid location")
    
    #Require the location to be valid in order to process the input
    req(valid_location)
    
    #If the location is valid, save the latitude and longitude for future calculations
    # if(valid_location) {
    #   query_lat <- str_c("SELECT PNrplat FROM place_names WHERE PNname=\"", str_to_upper(input$location), "\";");
    #   res_lat <- ;
    #   
    #   query_long <- str_c("SELECT PNrplat FROM place_names WHERE PNname=\"", str_to_upper(input$location), "\";");
    #   res_long <- ;
    # }
    
    #Close the in-scope DB connection
    dbDisconnect(con2)
    
    #TODO: Calculate the output
    
    #Display the result
    calculation <- str_c("The estimated profitability for ", input$crop, " in ", str_to_title(input$location), " is $X")
  })
})