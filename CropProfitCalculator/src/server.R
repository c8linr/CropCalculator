#
# Back end of the Crop Profitability Calculator
# Author: Caitlin Ross
#

#Load required libraries
library(shiny)
library(DBI)
library(config)
library(tidyverse)
library(stringi)

# Define server logic required to calculate profitability
shinyServer(function(input, output, session) {
  
  #Load different config parameters depending on whether I'm running the local or remote instance
  conn_args <- config::get('dataconnection')
  
  #Update the crop selection widget by loading the list of crops
  updateSelectInput(session, "crop", choices = load_croplist(conn_args))
  
  #Validate the location when the submit button is pressed
  output$calculation <- eventReactive(input$calculate, {
    #Break the user's input into place name and province
    loc_vector <- str_split_fixed(c(input$location), ",", n=2)
    place_name <- str_to_lower(str_c(loc_vector[1,1]))
    prov <- prov_name_clean(str_c(loc_vector[1,2]))
    
    #TODO: Fix the bug with accents in the result set
    valid_location <- verify_location(conn_args, place_name, prov)
    
    #Display a warning if the location is invalid
    shinyFeedback::feedbackWarning("location", !valid_location, str_c(str_to_title(place_name), ", ", prov, " is not a valid location"))
    
    #Require the location to be valid in order to process the input
    req(valid_location)
    
    #Get the estimated expense per acre
    est_expense <- estimate_expenses_per_acre(conn_args, prov)
    
    #Get the estimated revenue per acre
    est_revenue <- estimate_revenue_per_acre(conn_args, prov, input$crop)
    
    #Display the result
    calculation <- str_c("The estimated expenses for ",
                         input$crop,
                         " in ",
                         str_to_title(place_name),
                         ", ",
                         prov,
                         " is $",
                         prettyNum(est_expense, digits=4, format="g"),
                         " per acre")
  })
})

#Reads the DB to return the list of crops. Takes the DB connection arguments as input.
load_croplist <- function(conn_args) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Create the list of crops for the user to choose from
  crop_vector <- c(dbGetQuery(con, 
                              "SELECT NAME FROM croplist;"))
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Return the list of crops
  crop_vector
}

#Determines if the location is valid
verify_location <- function(conn_args, place, province) {
  # Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Get the result set of the query
  res_names <- c(dbGetQuery(con, 
                            str_c("SELECT DISTINCT place_names.PNname 
                                    FROM place_names 
                                    INNER JOIN province ON place_names.PRidu = province.PRcode
                                    WHERE place_names.PNname=\"", 
                                  place, 
                                  "\" AND province.PRname=\"", 
                                  province,
                                  "\";")))
  
  #Close the DB connection
  dbDisconnect(con)

  #Return whether the location is valid
  identical(place, str_remove_all(str_to_lower(stri_trans_nfd(str_c(res_names))), "[^a-z,A-Z]"))
}

#Returns the properly capitalized province name, in case the user inputted a partial name or code
prov_name_clean <- function(prov_input) {
  #First, decompose the string to remove accents and diacritics,
  #Then, make everything lower case,
  #Last, remove ALL non-letter characters
  clean_input <- str_remove_all(str_to_lower(stri_trans_nfd(str_c(prov_input))), "[^a-z,A-Z]")
  
  #Assign province names to variables to simplify the switch statement
  NL <- "Newfoundland and Labrador"
  PE <- "Prince Edward Island"
  NS <- "Nova Scotia"
  NB <- "New Brunswick"
  QC <- "Quebec"
  ON <- "Ontario"
  MB <- "Manitoba"
  SK <- "Saskatchewan"
  AB <- "Alberta"
  BC <- "British Columbia"
  YT <- "Yukon"
  NT <- "Northwest Territories"
  NU <- "Nunavut"
  
  switch(str_c(clean_input),
         "newfoundland" = NL,
         "labrador" = NL,
         "newfoundlandlabrador" = NL,
         "newfoundlandandlabrador" = NL,
         "nl" = NL,
         "nfld" = NL,
         "lab" = NL,
         "nf" = NL,
         "lb" = NL,
         "terreneuve" = NL,
         "tnl" = NL,
         "tn" = NL,
         "princeedwardisland" = PE,
         "pei" = PE,
         "pe" = PE,
         "ileduprinceedouard" = PE,
         "ileduprinceedward" = PE,
         "ipe" = PE,
         "novescotia" = NS,
         "ns" = NS,
         "nouvelleecosse" = NS,
         "ne" = NS,
         "newbrunswick" = NB,
         "nb" = NB,
         "nouveaubrunswick" = NB,
         "quebec" = QC,
         "qc" = QC,
         "que" = QC,
         "pq" = QC,
         "provincedequebec" = QC,
         "qb" = QC,
         "ontario" = ON,
         "on" = ON,
         "ont" = ON,
         "manitoba" = MB,
         "mb" = MB,
         "man" = MB,
         "saskatchewan" = SK,
         "sk" = SK,
         "sask" = SK,
         "alberta" = AB,
         "ab" = AB,
         "alta" = AB,
         "alb" = AB,
         "britishcolumbia" = BC,
         "bc" = BC,
         "colombiebritannique" = BC,
         "cb" = BC,
         "yukon" = YT,
         "yukonterritory" = YT,
         "yt" = YT,
         "yk" = YT,
         "yn" = YT,
         "yuk" = YT,
         "northwestterritories" = NT,
         "northwest" = NT,
         "nt" = NT,
         "nwt" = NT,
         "territoiresdunordoest" = NT,
         "tno" = NT,
         "nunavut" = NU,
         "nu" = NU,
         "nvt" = NU,
         "nv" = NU,
         "Invalid Province")
}

estimate_expenses_per_acre <- function(conn_args, prov) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Get the estimated expenses per acre
  expense_res <- dbGetQuery(con,
                        str_c("SELECT (sum(exp.VALUE) / sum(land.VALUE))",
                              " FROM operating_expenses AS exp ",
                              "INNER JOIN census_land_use AS land ",
                              "ON exp.GEO = land.GEO ",
                              "WHERE exp.GEO LIKE \"%", prov, "%\" ",
                              "AND exp.UOM=\"Dollars\" ",
                              "AND land.LAND_USE LIKE \"Land in crops%\" ",
                              "AND land.UOM = \"Acres\";"))
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Return the result
  expense_res
}

estimate_revenue_per_acre <- function(conn_args, prov, crop) {
  #Connect to the database
  con <- dbConnect(odbc::odbc(),
                   Driver = conn_args$driver,
                   Server = conn_args$server,
                   UID = conn_args$uid,
                   PWD = conn_args$pwd,
                   Port = conn_args$port,
                   Database = conn_args$database)
  
  #Get the estimated yield per acre in kilograms
  
  
  #Get the estimated price per kilo
  
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Return the estimated revenue per acre (yield x price)
}