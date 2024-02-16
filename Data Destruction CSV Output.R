library(bigrquery)
library(dplyr)
library(gmodels)
library(epiDisplay)
library(lubridate)
library(tidyverse)
library(gt)
library(knitr)
library(gtsummary)
#install_tinytex()
library(tinytex)
library(vtable)
library(kableExtra)



bq_auth()
2



project_cc = "nih-nci-dceg-connect-prod-6d04"
datad_query <- "SELECT  Connect_ID, d_827220437, d_831041022, d_883668444, d_130371375_d_266600170_d_731498909, d_130371375_d_266600170_d_648936790, d_130371375_d_496823485_d_731498909, d_130371375_d_496823485_d_648936790, d_130371375_d_650465111_d_731498909, d_130371375_d_650465111_d_648936790, d_130371375_d_303552867_d_731498909, d_130371375_d_303552867_d_648936790, d_269050420, d_359404406, d_949302066, d_536735468, d_976570371, d_663265240, d_253883960, d_459098666,  d_265193023, d_126331570, d_878865966, d_167958071, d_684635302, d_100767870, d_119449326  FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP` where Connect_ID IS NOT NULL"  #d_220186468,
spec_query <- "SELECT Connect_ID, d_820476880 FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.biospecimen_JP` where Connect_ID is not null"

datad_table_cc <- bq_project_query(project_cc, datad_query)
datad <- bq_table_download(datad_table_cc, bigint = "integer64")

spec_table_cc <- bq_project_query(project_cc, spec_query)
spec <- bq_table_download(spec_table_cc, bigint = "integer64")

spec$Connect_ID <- as.numeric(spec$Connect_ID)
datad$Connect_ID <- as.numeric(datad$Connect_ID)

variables <- left_join(datad, spec, by="Connect_ID")







currentDate <- Sys.Date()

variables <- variables %>%  filter(d_831041022=="353358909")

destruction <- variables %>% mutate('Data Destruction Flag'= case_when(d_831041022=="353358909" ~ "Yes",
                                                                       d_831041022=="104430631" ~ "No"),
                                    'Data Destruction Form Flag'= case_when(d_359404406=="353358909" ~ "Yes",
                                                                            d_359404406=="104430631" ~ "No"),
                                    'Eligible for Basline Survey Incentive'= case_when(d_130371375_d_266600170_d_731498909=="353358909" ~ "Yes",
                                                                                       d_130371375_d_266600170_d_731498909=="104430631" ~ "No"),
                                    'Eligible for Follow-up 1 Incentive'= case_when(d_130371375_d_496823485_d_731498909=="353358909" ~ "Yes",
                                                                                    d_130371375_d_496823485_d_731498909=="104430631" ~ "No"),
                                    'Eligible for Follow-up 2 Incentive'= case_when(d_130371375_d_650465111_d_731498909=="353358909" ~ "Yes",
                                                                                    d_130371375_d_650465111_d_731498909=="104430631" ~ "No"),
                                    'Eligible for Follow-up 3 Incentive'= case_when(d_130371375_d_303552867_d_731498909=="353358909" ~ "Yes",
                                                                                    d_130371375_d_303552867_d_731498909=="104430631" ~ "No"),
                                    'Recieved Basline Survey Incentive'= case_when(d_130371375_d_266600170_d_648936790=="353358909" ~ "Yes",
                                                                                   d_130371375_d_266600170_d_648936790=="104430631" ~ "No"),
                                    'Recieved Follow-up 1 Incentive'= case_when(d_130371375_d_496823485_d_648936790=="353358909" ~ "Yes",
                                                                                d_130371375_d_496823485_d_648936790=="104430631" ~ "No"),
                                    'Recieved Follow-up 2 Incentive'= case_when(d_130371375_d_650465111_d_648936790=="353358909" ~ "Yes",
                                                                                d_130371375_d_650465111_d_648936790=="104430631" ~ "No"),
                                    'Recieved Follow-up 3 Incentive'= case_when(d_130371375_d_303552867_d_648936790=="353358909" ~ "Yes",
                                                                                d_130371375_d_303552867_d_648936790=="104430631" ~ "No"),
                                    Site= case_when(d_827220437== 531629870 ~ "HealthPartners", 
                                                    d_827220437==548392715 ~ "Henry Ford Health System",
                                                    d_827220437== 303349821 ~ "Marshfield Clinic Health System",
                                                    d_827220437== 657167265 ~"Sanford Health" , 
                                                    d_827220437== 809703864~ "University of Chicago Medicine",
                                                    d_827220437== 125001209 ~ "Kaiser Permanente Colorado",
                                                    d_827220437== 327912200 ~ "Kaiser Permanente Georgia",
                                                    d_827220437== 300267574 ~ "Kaiser Permanente Hawaii" ,
                                                    d_827220437== 452412599 ~ "Kaiser Permanente Northwest" ,
                                                    d_827220437== 517700004 ~ "National Cancer Institute" ,
                                                    d_827220437== 13 ~ "National Cancer Institute" ,
                                                    d_827220437== 181769837 ~ "Other" ),
                                    'All Baseline Surveys Completed'= case_when(d_100767870==353358909 ~ "Yes",
                                                                                d_100767870==104430631 ~ "No"),
                                    'Biospeimen (BU or BUM) Survey Flag'= case_when((d_253883960==972455046 | d_265193023 ==972455046) ~ "Not Started",
                                                                                    (d_253883960==615768760 | d_265193023 ==615768760) ~ "Started",
                                                                                    (d_253883960==231311385 | d_265193023 ==231311385) ~ "Completed"),
                                    'SSN Survey Flag'= case_when(d_126331570==972455046 ~ "Not Started",
                                                                 d_126331570==615768760 ~ "Started",
                                                                 d_126331570==231311385 ~ "Completed"),
                                    'Menstrual Cycle Survey Flag'= case_when(d_459098666==972455046 ~ "Not Started",
                                                                             d_459098666==615768760 ~ "Started",
                                                                             d_459098666==231311385 ~ "Completed"),
                                    # 'COVID Survey Flag'= case_when(d_220186468==972455046 ~ "Not Started",
                                    #                                                 d_220186468==615768760 ~ "Started",
                                    #                                                 d_220186468==231311385 ~ "Completed"),
                                    'Blood Collected'=case_when(d_878865966=="353358909" ~ "Yes",
                                                                d_878865966=="104430631" ~ "No"),
                                    'Urine Collected'=case_when(d_167958071=="353358909" ~ "Yes",
                                                                d_167958071=="104430631" ~ "No"),
                                    'Mouthwash Collected'=case_when(d_684635302=="353358909" ~ "Yes",
                                                                    d_684635302=="104430631" ~ "No"),
                                    'Collection ID(s)'=case_when((d_684635302=="353358909" | d_167958071=="353358909" | d_878865966=="353358909") ~ d_820476880))

destruction$'Data Destruction Date Requested' <- destruction$d_269050420
destruction$'Date of Singed Data Destruction Flag' <- destruction$d_119449326

Data_destruction <- destruction %>% select(Connect_ID, Site, 'Data Destruction Flag', 'Data Destruction Date Requested', 'Data Destruction Form Flag', 'Date of Singed Data Destruction Flag', 'All Baseline Surveys Completed','Biospeimen (BU or BUM) Survey Flag', 'SSN Survey Flag', 'Menstrual Cycle Survey Flag',  'Blood Collected', 'Urine Collected', 'Mouthwash Collected', 'Collection ID(s)', 'Eligible for Basline Survey Incentive', 'Eligible for Follow-up 1 Incentive', 'Eligible for Follow-up 2 Incentive', 'Eligible for Follow-up 3 Incentive', 'Recieved Basline Survey Incentive', 'Recieved Follow-up 1 Incentive', 'Recieved Follow-up 2 Incentive', 'Recieved Follow-up 3 Incentive') 
#'COVID Survey Flag',
Data_destruction

knitr::kable(Data_destruction)

write.csv(Data_destruction,paste("C:/Users/dowlingk2/Documents/GitHub/Data_Destruction_Requests_",currentDate,".csv",sep=""),row.names = F,na="")
