
#(2024-005 Jackson) to look at SOGI data in Connect vs the EHR at Health Partners
  

##################################### Libraries 
rm(list = ls())
library(bigrquery)
library(foreach)
library(stringr)
#library(plyr)
#library(expss) ###to add labels
library(epiDisplay) ##recommended applied here crosstable, tab1
library(gmodels) ##recommended
library(magrittr)
library(arsenal)
library(gtsummary)
library(rio)



library(ggplot2)
library(gridExtra)
library(scales)
library(gt)
#install(tinytex)
library(tinytex)
library(data.table) ###to write or read and data management 
library(tidyverse) ###for data management
library(dplyr) ###data management
library(reshape)  ###to work on transition from long to wide or wide to long data
library(listr) ###to work on a list of vector, files or..
library(sqldf) ##sql
library(lubridate) ###date time
library(stringr) ###to work on patterns, charaters
library(kableExtra)


options(tinytex.verbose = TRUE)

bq_auth()
2


############################## Module 1 Merge

#Data Dictionary for column names
dictionary <- rio::import("https://episphere.github.io/conceptGithubActions/aggregate.json",format = "json")
dd <- dplyr::bind_rows(dictionary,.id="CID")
dd <-rbindlist(dictionary,fill=TRUE,use.names=TRUE,idcol="CID")
dd$`Variable Label`[is.na(dd$`Variable Label`)] <- replace_na(dd$'Variable Name')
dd <- as.data.frame.matrix(do.call("rbind",dictionary)) 
dd$CID <- rownames(dd)
#https://shaivyakodan.medium.com/7-useful-r-packages-for-analysis-7f60d28dca98
devtools::install_github("tidyverse/reprex")





## BQ Pull from the participants table just to use for versioning
project <- "nih-nci-dceg-connect-prod-6d04"
billing <- "nih-nci-dceg-connect-prod-6d04" 
recr_M1 <- bq_project_query(project, query="SELECT token,Connect_ID, d_821247024, d_914594314,  d_827220437,d_512820379,
                            d_949302066 , d_517311251  FROM  `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP` WHERE  d_821247024='197316935' and d_949302066 ='231311385'")
recr_m1 <- bq_table_download(recr_M1,bigint = "integer64")
cnames <- names(recr_m1)
# Check that it doesn't match any non-number
numbers_only <- function(x) !grepl("\\D", x)
# to check variables in recr_noinact_wl1
for (i in 1: length(cnames)){
  varname <- cnames[i]
  var<-pull(recr_m1,varname)
  recr_m1[,cnames[i]] <- ifelse(numbers_only(var), as.numeric(as.character(var)), var)
}




#### Handling participants that somehow completed both Mod1 version 1 and Mod1 version 2

sql_M1_1 <- bq_project_query(project, query = "SELECT * FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.module1_v1_JP` WHERE Connect_ID IS NOT NULL")
sql_M1_2 <- bq_project_query(project, query = "SELECT * FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.module1_v2_JP` WHERE Connect_ID IS NOT NULL")

M1_V1 <- bq_table_download(sql_M1_1, bigint = "integer64")
M1_V2 <- bq_table_download(sql_M1_2, bigint = "integer64")

# Select matching column names
M1_V1_vars <- colnames(M1_V1)
M1_V2_vars <- colnames(M1_V2)
common_vars <- intersect(M1_V1_vars, M1_V2_vars)

# Subset to common columns
M1_V1_common <- M1_V1[, common_vars]
M1_V2_common <- M1_V2[, common_vars]

# Add version indicator
M1_V1_common$version <- 1
M1_V2_common$version <- 2

# Identify columns with mismatched types
mismatched_cols <- names(M1_V1_common)[sapply(names(M1_V1_common), function(col) {
  class(M1_V1_common[[col]]) != class(M1_V2_common[[col]])
})]

# Convert mismatched columns to character for consistency
M1_V1_common <- M1_V1_common %>%
  mutate(across(all_of(mismatched_cols), as.character))
M1_V2_common <- M1_V2_common %>%
  mutate(across(all_of(mismatched_cols), as.character))

# Combine both versions for participants who completed both
M1_common <- bind_rows(M1_V1_common, M1_V2_common) %>%
  arrange(Connect_ID, desc(version))

# For columns unique to each version
V1_only_vars <- setdiff(M1_V1_vars, common_vars)
V2_only_vars <- setdiff(M1_V2_vars, common_vars)

# Subset each version for unique columns and add version indicator
m1_v1_only <- M1_V1[, c("Connect_ID", V1_only_vars)] %>%
  mutate(version = 1)
m1_v2_only <- M1_V2[, c("Connect_ID", V2_only_vars)] %>%
  mutate(version = 2)

# Combine the unique and common data
m1_common_v1 <- left_join(M1_common, m1_v1_only, by = c("Connect_ID", "version"))
m1_combined_v1v2 <- left_join(m1_common_v1, m1_v2_only, by = c("Connect_ID", "version"))

# Filter for complete cases where specific completion criteria are met
m1_complete <- m1_combined_v1v2 %>%
  filter(Connect_ID %in% recr_m1$Connect_ID[recr_m1$d_949302066 == 231311385]) %>%
  arrange(desc(version))

# Remove duplicates, keeping only the most recent version for each Connect_ID
m1_complete_nodup <- m1_complete[!duplicated(m1_complete$Connect_ID),]

m1_complete_nodup$Connect_ID <- as.numeric(m1_complete_nodup$Connect_ID)


### Define requirements of the data: active or passive,  user profile done, consented, mod1 done, verified
parts_SJ <- "SELECT Connect_ID, token, d_949302066, d_536735468, d_976570371, d_663265240, d_100767870, d_517311251
FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP` 
where Connect_ID IS NOT NULL and (d_512820379='486306141' OR d_512820379='854703046') and d_821247024='197316935' and
(d_919254129='353358909') and (d_699625233='353358909') and d_827220437='531629870'"
parts_table_SJ <- bq_project_query(project, parts_SJ)
parts_data_SJ <- bq_table_download(parts_table_SJ, bigint = "integer64")

parts_data_SJ$Connect_ID <- as.numeric(parts_data_SJ$Connect_ID) ###need to convert type- m1... is double and parts is character

sj_data= left_join(parts_data_SJ, m1_complete_nodup, by="Connect_ID") 
dim(sj_data)





########################## Labeling Data

sj_data <- sj_data %>%  mutate(BL_Module_Completion_Status = case_when(d_100767870==353358909 ~ "All Baseline Modules Completed",
                                                                       TRUE ~ "One or More Baseline Modules Not Completed"),
                               BOH_status=case_when(d_949302066==615768760 ~ "Started",
                                                    d_949302066==231311385 ~ "Submitted",
                                                    TRUE ~ "Not Started"))


multi_race=0    
for (i in 1:length(sj_data$Connect_ID)){
  AI=ifelse((sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 & (sj_data$D_384191091_D_384191091_D_636411467[[i]]==1 | sj_data$D_384191091_D_384191091_D_458435048[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 | sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  As=ifelse((sj_data$D_384191091_D_384191091_D_636411467[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_458435048[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 | sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  Bl=ifelse((sj_data$D_384191091_D_384191091_D_458435048[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_636411467[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 | sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  Hs=ifelse((sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_636411467[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_458435048[[i]]==1 | sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  Me=ifelse((sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_636411467[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_458435048[[i]]==1 | sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  Hw=ifelse((sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_636411467[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_458435048[[i]]==1 | sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 | sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  Wh=ifelse((sj_data$D_384191091_D_384191091_D_412790539[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_636411467[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_458435048[[i]]==1 | sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_807835037[[i]]==1)), 1, 0)
  Ot=ifelse((sj_data$D_384191091_D_384191091_D_807835037[[i]]==1 & (sj_data$D_384191091_D_384191091_D_583826374[[i]]==1 | sj_data$D_384191091_D_384191091_D_636411467[[i]]==1|
                                                                      sj_data$D_384191091_D_384191091_D_458435048[[i]]==1 | sj_data$D_384191091_D_384191091_D_706998638[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_586825330[[i]]==1 | sj_data$D_384191091_D_384191091_D_973565052[[i]]==1 |
                                                                      sj_data$D_384191091_D_384191091_D_412790539[[i]]==1)), 1, 0)
  multi_race= multi_race + sum(AI+As+Bl+Hs+Me+Hw+Wh+Ot, na.rm=T)
  
}



sj_data$multi_racial <- c(rep(1, times=multi_race), rep(0, times=(dim(sj_data)[1]- multi_race)))



## RACE

sj_data <- sj_data %>%  mutate(Race= case_when(BOH_status=="Not Started" ~ "NA",
                                               multi_racial==1 ~ "Multi-Racial",
                                               D_384191091_D_384191091_D_583826374==1 ~ "American Indian or Native American",
                                               D_384191091_D_384191091_D_636411467==1 ~ "Asian/Asian American",
                                               D_384191091_D_384191091_D_458435048==1 ~ "Black, African American, or African",
                                               D_384191091_D_384191091_D_706998638==1 ~ "Hispanic, Latino, or Spanish",
                                               D_384191091_D_384191091_D_973565052==1 ~ "Middle Eastern or North African",
                                               D_384191091_D_384191091_D_586825330==1 ~ "Hawaiian or Pacific Islander",
                                               D_384191091_D_384191091_D_412790539==1 ~ "White",
                                               (D_384191091_D_384191091_D_807835037==1 | !is.na(D_384191091_D_747350323)) ~ "Other",
                                               D_384191091_D_384191091_D_746038746==1 ~ "Prefer Not to Answer",
                                               TRUE  ~ "Skipped this question "),
                               Ethnicity = case_when(BOH_status=="Not Started" ~ "NA",
                                                     Race=="Hispanic, Latino, or Spanish" ~ "Hispanic",
                                                     TRUE ~ "Non-Hispanic"),
                               Gender= case_when(BOH_status=="Not Started" ~ "NA",
                                                 D_289664241_D_289664241==536341288 | D_289664241_D_289664241==218837028 ~ "Woman",
                                                 D_289664241_D_289664241==654207589 | D_289664241_D_289664241==983318667 ~ "Man",
                                                 D_289664241_D_289664241==405267600 ~ "Transgender Man",
                                                 D_289664241_D_289664241==873138103 ~ "Transgender Woman",
                                                 D_289664241_D_289664241==805712793 ~ "Genderqueer",
                                                 D_289664241_D_289664241==486192236 ~ "Non-binary",
                                                 D_289664241_D_289664241==807835037 | !is.na(D_289664241_D_918409306) ~ "Other",
                                                 D_289664241_D_289664241==746038746 ~ "Prefer Not to Answer",
                                                 TRUE ~ "Skipped this Question"),
                               Sex=case_when(BOH_status=="Not Started" ~ "NA",
                                             D_407056417=="536341288" ~ "Female",
                                             D_407056417=="654207589" ~ "Male",
                                             D_407056417=="576796184" ~ "Intersex or Other",
                                             TRUE ~ "Skipped this Question"),
                               Sexual_Orientation = case_when(BOH_status=="Not Started" ~ "NA",
                                                              D_555481393_D_555481393=="271882746"~"Straight or heterosexual", 
                                                              D_555481393_D_555481393=="903084185"~"Lesbian, gay, or homosexual", 
                                                              D_555481393_D_555481393=="999994434"~"Bisexual", 
                                                              D_555481393_D_555481393=="197935377" ~"Queer", 
                                                              D_555481393_D_555481393=="210894509"	~ "No labels", 
                                                              D_555481393_D_555481393=="727200870" ~ "Asexual", 
                                                              D_555481393_D_555481393=="832978839"	 ~ "Mostly Straight", 
                                                              D_555481393_D_555481393=="854349138" ~ "Pansexual",
                                                              D_555481393_D_555481393=="410008111" ~ "Two-Spirit",
                                                              D_555481393_D_555481393=="831942158" ~ "Questioning",
                                                              D_555481393_D_555481393=="807835037" | !is.na(D_555481393_D_979809707) ~ "Other",
                                                              TRUE ~ "Skipped this Question"),
                              Module1_Completion_Date = as.Date(d_517311251))
sj_data$Sexual_Orientation_Text <- ifelse(!is.na(sj_data$D_555481393_D_979809707), sj_data$D_555481393_D_979809707, "NA")
sj_data$Gender_Text <- ifelse(!is.na(sj_data$D_289664241_D_918409306), sj_data$D_289664241_D_918409306, "NA")







############### CSV file

sj_data_csv <- sj_data %>%  dplyr::select(Connect_ID, BL_Module_Completion_Status, BOH_status, Module1_Completion_Date, Race, Ethnicity, Gender, Gender_Text, Sex, Sexual_Orientation, Sexual_Orientation_Text)
write.csv(sj_data_csv,paste0('2024_005_Jackson_Study_Data_HP_', Sys.Date(), '.csv'), row.names = F,na="")





