library(bigrquery)
library(sqldf) 
library(glue)
bq_auth()

project <- "nih-nci-dceg-connect-prod-6d04"

#write_to_local_drive = F
local_drive= ifelse(write_to_local_drive, "C:/Users/dowlingk2/Documents/GitHub/ccc_module_metrics_gcp_pipeline/", "")
boxfolder <- 275062283610 # Active Box Folder

currentDate <- Sys.Date()


Flag <-"SELECT Connect_ID, 
CASE 
    WHEN d_289750687 is null THEN 'No'
    WHEN d_289750687 = 353358909 THEN 'Yes'
  END AS Derived_Eligibility_Flag, 
CASE 
    WHEN d_459098666 = 231311385 THEN 'Completed'
    WHEN d_459098666 = 615768760 THEN 'Started'
  END AS Completion_Status,
d_844088537 as Time_Survey_Started  
 FROM `nih-nci-dceg-connect-prod-6d04.Connect.participants` 
where d_289750687 is null and (d_459098666=231311385 or d_459098666=615768760)
order by d_844088537 desc"


Flag_table <- bq_project_query(project, Flag)
FlagOutput <- bq_table_download(Flag_table, bigint = "integer64") 

write.csv(FlagOutput,glue("{local_drive}MC_Survey_Eligibility_{currentDate}_boxfolder_{boxfolder}.csv"),row.names = F,na="")
