#
# Back end of the Crop Profitability Calculator
# Author: Caitlin Ross
#

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
    # Connect to the database IN SCOPE
    con <- dbConnect(odbc::odbc(),
                      Driver = conn_args$driver,
                      Server = conn_args$server,
                      UID = conn_args$uid,
                      PWD = conn_args$pwd,
                      Port = conn_args$port,
                      Database = conn_args$database)
    
    #Break the user's input into place name and province
    loc_vector <- str_split_fixed(c(input$location), ",", n=2)
    place_name <- str_to_lower(str_c(loc_vector[1,1]))
    prov <- prov_name_clean(str_c(loc_vector[1,2]))
    
    #Get the result set of the query
    res_names <- c(dbGetQuery(con, 
                              str_c("SELECT DISTINCT place_names.PNname 
                                    FROM place_names 
                                    INNER JOIN province ON place_names.PRidu = province.PRcode
                                    WHERE place_names.PNname=\"", 
                                    place_name, 
                                    "\" AND province.PRname=\"", 
                                    prov,
                                    "\";")))
    
    #Determine if the location is valid
    valid_location <- identical(place_name, c(tolower(res_names)))
    
    #Display a warning if the location is invalid
    shinyFeedback::feedbackWarning("location", !valid_location, str_c(place_name, ", ", prov, " is not a valid location"))
    
    #Require the location to be valid in order to process the input
    req(valid_location)
    
    #Create variables to hold the latitude and longitude, assign them the null value
    lat <- long <- NA
    
    #If the location is valid, save the latitude and longitude for future calculations
    if(valid_location) {
      res_lat <- c(dbGetQuery(con, 
                              str_c("SELECT PNrplat FROM place_names WHERE PNname=\"", 
                                    str_to_upper(input$location), 
                                    "\";")))
      lat <- res_lat[0]

      res_long <- c(dbGetQuery(con, 
                               str_c("SELECT PNrplat FROM place_names WHERE PNname=\"", 
                                     str_to_upper(input$location), 
                                     "\";")))
      long <- res_long[0]
    }
    
    #Close the in-scope DB connection
    dbDisconnect(con)
    
    #TODO: Calculate the output

    
    #Display the result
    calculation <- str_c("The estimated profitability for ", input$crop, " in ", str_to_title(place_name), ", ", prov, " is $X")
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
                              "SELECT crop FROM crop_list;"))
  
  #Disconnect from the database
  dbDisconnect(con)
  
  #Return the list of crops
  crop_vector
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

#Returns the closest location in the dataset to the user's chosen location
closest_location <- function(lat, long, dataset) {
  #TODO: find closest location in result set
}