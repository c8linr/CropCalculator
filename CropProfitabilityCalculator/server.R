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
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Update the crop selection widget
  updateSelectInput(session, "crop", choices = crop_vector)
  
  #Validate the location when the submit button is pressed
  output$calculation <- eventReactive(input$calculate, {
    # Connect to the database IN SCOPE
    con2 <- dbConnect(RMariaDB::MariaDB(), default.file='..\\.my.cnf', group='rs-dbi', dbname='cropdata')
    
    # Construct the query string
    query <- str_c("SELECT DISTINCT PNname FROM cropdata.place_names WHERE PNname=\"", str_to_lower(input$location), "\";")
    
    #Get the result set of the query
    res <- c(dbGetQuery(con2, query))
    
    #Determine if the location is valid
    valid_location <- identical(c(str_to_lower(input$location)), c(tolower(res)))
    
    #Display a warning if the location is invalid
    shinyFeedback::feedbackWarning("location", !valid_location, "Invalid location")
    
    #Require the location to be valid
    req(valid_location)
    
    #Close the in-scope DB connection
    dbDisconnect(con2)
    
    #Display the result
    calculation <- str_c("The estimated profitability for ", input$crop, " in ", str_to_title(input$location), " is $X")
  })
})