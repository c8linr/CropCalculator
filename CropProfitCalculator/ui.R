#
# Shiny App UI
# Project: Crop Profitability Calculator
# File: ui.R
# Author: Caitlin Ross
# Last Modified: 2022/04/13
#


#Load required library
library(shiny)

# Define UI for application
shinyUI(fluidPage(
    shinyFeedback::useShinyFeedback(),
    
    # Application title
    titlePanel("Canadian Crop Profitability Calculator"),

    #Select the crop
    selectInput("crop", label = "Select Crop", choices = NULL),
    
    #Input the location
    textInput("location", label="Enter Location, Including Province"),
    
    #Submit button
    actionButton("calculate", "Calculate"),
    
    #Output the profitability calculation
    textOutput("calculation")
))
