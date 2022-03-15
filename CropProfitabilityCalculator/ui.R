#
# UI for the Crop Profitability Calculator
# Author: Caitlin Ross
#

library(shiny)

# Define UI for application
shinyUI(fluidPage(
    shinyFeedback::useShinyFeedback(),
    
    # Application title
    titlePanel("Canadian Crop Profitability Calculator"),

    #Select the crop
    selectInput("crop", label = "Select Crop", choices = NULL),
    
    #Input the location
    textInput("location", label="Enter Location"),
    
    #Submit button
    actionButton("calculate", "Calculate"),
    
    #Output the profitability calculation
    textOutput("calculation")
))
