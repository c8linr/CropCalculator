#
# Functions (non-database)
# Project: Crop Profitability Calculator
# File: functions.R
# Author: Caitlin Ross
# Last Modified: 2022/04/13
#


# Returns the properly capitalized province name
# Takes the province as a character vector
# Used in case the user inputs code, improper capitalization, French, etc.
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