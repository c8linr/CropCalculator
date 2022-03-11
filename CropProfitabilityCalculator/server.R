#
# Back end of the Crop Profitability Calculator
# Author: Caitlin Ross
#

if (!require("pacman")) install.packages("pacman")
pacman::p_load(pacman, DBI, shiny, RMariaDB)

# Define server logic required to calculate profitability
shinyServer(function(input, output) {
  #Connect to the database
  con <- dbConnect(RMariaDB::MariaDB(), default.file='..\\.my.cnf', group='rs-dbi', dbname='cropdata')
  
  #Disconnect from the database
  dbDisconnect(con)
})