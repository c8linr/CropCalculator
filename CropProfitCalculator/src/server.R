#
# Back end
# Crop Profitability Calculator
# Author: Caitlin Ross
# Last Modified: 2022/04/10
#


#Load required libraries
library(shiny)
library(config)
library(DBI)
library(tidyverse)
library(stringi)

#Load the functions defined in other files
source("functions.R")
source("dbfunctions.R")
source("classdefs.R")

# Define server logic required to calculate profitability
shinyServer(function(input, output, session) {
  
  #Load different config parameters depending on whether I'm running the local or remote instance
  conn_args <- config::get('dataconnection')
  
  #Update the crop selection widget by loading the list of crops
  updateSelectInput(session, "crop", choices = load_croplist(conn_args))
  
  #Validate the location when the submit button is pressed
  output$calculation <- eventReactive(input$calculate, {
    #Split the user's input into place name and province
    loc_vector <- str_split_fixed(c(input$location), ",", n=2)
    place_name <- str_to_lower(str_c(loc_vector[1,1]))
    prov <- prov_name_clean(str_c(loc_vector[1,2]))
    
    #TODO: Fix the bug with accents in the result set
    valid_location <- verify_location(conn_args, place_name, prov)
    
    #Display a warning if the location is invalid
    shinyFeedback::feedbackWarning("location", !valid_location, str_c(str_to_title(place_name), ", ", prov, " is not a valid location"))
    
    #Require the location to be valid in order to process the input
    req(valid_location)
    
    #Calculate the profit (revenue/ace - expenses/ace)
    est_profit <- est_rev(conn_args, prov, input$crop) - est_exp(conn_args, prov)
    
    #Display the result
    calculation <- str_c("The estimated profit for ",
                         input$crop,
                         " in ",
                         str_to_title(place_name),
                         ", ",
                         prov,
                         " is $",
                         prettyNum(est_profit, digits=4, format="g"),
                         " per acre")
  })
})

