#
# Shiny App back-end
# Project: Crop Profitability Calculator
# File: server.R
# Author: Caitlin Ross
# Last Modified: 2022/04/13
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

# Define server logic required to calculate profitability
shinyServer(function(input, output, session) {
  
  #Load different config parameters depending on whether I'm running the local or remote instance
  conn_args <- config::get('dataconnection')
  
  #Update the crop selection widget by loading the list of crops
  updateSelectInput(session, "crop", choices = load_croplist(conn_args))
  
  #Validate the location and display the calculation when the submit button is pressed
  output$calculation <- eventReactive(input$calculate, {
    #Save the crop choice
    crop_choice <- list(name=input$crop, type=get_crop_type(conn_args, input$crop))
    
    #Split the user's input into place name and province
    loc_vector <- str_split_fixed(c(input$location), ",", n=2)
    
    #Save the place name and province as a list
    location_choice <- list(place=str_to_lower(str_c(loc_vector[1,1])),
                            province=prov_name_clean(str_c(loc_vector[1,2])))
    
    #Check if the location exists in the database
    valid_location <- verify_location(conn_args, location_choice)
    
    #Display a warning if the location is invalid
    shinyFeedback::feedbackWarning("location",
                                   !valid_location,
                                   str_c(str_to_title(location_choice$place),
                                         ", ",
                                         location_choice$province,
                                         " is not a valid location"))
    
    #Require the location to be valid in order to process the input
    req(valid_location)
    
    #Calculate the profit (revenue/ace - expenses/ace)
    est_profit <- est_rev(conn_args, location_choice, crop_choice)
                - est_exp(conn_args, location_choice)
    
    #Display the result
    calculation <- str_c("The estimated profit for ",
                         crop_choice$name,
                         " in ",
                         str_to_title(location_choice$place),
                         ", ",
                         location_choice$province,
                         " is $",
                         format(est_profit,
                                trim=TRUE,
                                digits=3,
                                nsmall=2),
                         " per acre")
  })
})

