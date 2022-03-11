#
# UI for the Crop Profitability Calculator
# Author: Caitlin Ross
#

if (!require("pacman")) install.packages("pacman")
pacman::p_load(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Canadian Crop Profitability Calculator"),

    #Select the crop
    selectInput("crop", label = "Select Crop", choices = NULL)
))
