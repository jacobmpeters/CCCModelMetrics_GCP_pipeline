#R Sansale
#last updated: 7/3/24
#task: https://github.com/episphere/connect/issues/1045
#organization: query/task 1 lines 6-121
#task 2: lines 154-end

#data destruction request #1
#ensure all stub data retained
#ensure remainder of participants table data has been deleted


# Load necessary libraries
library(bigrquery)
library(dplyr)
library(openxlsx)

# Run the query and download the data
connect_ids <- data.frame(Connect_ID = c('8003874306'))

project_id <- "nih-nci-dceg-connect-prod-6d04"
filename <- paste0("/Users/sansalerj/Desktop/adhoc_requests/data_destruction/prod_testing/", connect_ids, ".xlsx")
token <- "bbd1254c-11f0-494e-8cd6-5ac145944f13"


# Pull the entire participants table for the specified Connect_IDs
sql_query <- sprintf(
  "SELECT *
   FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP`
   WHERE Connect_ID IN (%s)",
  paste(sprintf("'%s'", connect_ids$Connect_ID), collapse = ", ")
)


# Run the query and download the data
query_job <- bq_project_query(project_id, sql_query)
participants_data <- bq_table_download(query_job, bigint = "integer64")


# Load the variable names from the CSV file
data_destruction_variables <- read.csv("/Users/sansalerj/Desktop/adhoc_requests/data_destruction/data_destruction_variables.csv")
variable_names <- data_destruction_variables$variable.name

# Convert variable names containing periods to all uppercase and then replace periods with underscores
variable_names <- sapply(variable_names, function(x) {
  if (grepl("\\.", x)) {
    x <- toupper(x)
    x <- gsub("\\.", "_", x)
  }
  return(x)
})

# Identify variables not in the original variable_names list
all_variable_names <- colnames(participants_data)
other_variable_names <- setdiff(all_variable_names, variable_names)

# Initialize an empty dataframe to store counts for specified variables
counts_df <- data.frame(
  Variable = character(),
  Non_Null_Count = integer(),
  Null_Count = integer(),
  stringsAsFactors = FALSE
)



# Count null/non-null values for specified variables
for (variable in variable_names) {
  if (variable %in% all_variable_names) {
    non_null_count <- sum(!is.na(participants_data[[variable]]))
    null_count <- sum(is.na(participants_data[[variable]]))
    
    counts_df <- rbind(counts_df, data.frame(
      Variable = variable,
      Non_Null_Count = non_null_count,
      Null_Count = null_count,
      stringsAsFactors = FALSE
    ))
  }
}

# Print the dataframe with counts for specified variables
print(counts_df)




# Initialize an empty dataframe to store counts for other variables
other_counts_df <- data.frame(
  Variable = character(),
  Non_Null_Count = integer(),
  Null_Count = integer(),
  stringsAsFactors = FALSE
)

# Count null/non-null values for other variables
for (variable in other_variable_names) {
  non_null_count <- sum(!is.na(participants_data[[variable]]))
  null_count <- sum(is.na(participants_data[[variable]]))
  
  other_counts_df <- rbind(other_counts_df, data.frame(
    Variable = variable,
    Non_Null_Count = non_null_count,
    Null_Count = null_count,
    stringsAsFactors = FALSE
  ))
}

# Print the dataframe with counts for other variables
print(other_counts_df)


# Create a new workbook
wb2 <- createWorkbook()

#table 1 variables
addWorksheet(wb2, "query1_table1_counts")
writeData(wb2, "query1_table1_counts", counts_df)

#complement of table 1 variables
addWorksheet(wb2, "query1_table1_other_variables")
writeData(wb2, "query1_table1_other_variables", other_counts_df)































#request #2
#ensure that data is deleted or preserved for each of the following tables:
#notifications, boxes, biospecimen, kitassembly, canceroccurrence
#have to split this into 3 queries since notifications and boxes table
#do not have connect ID



# List of tables to check
tables <- c("biospecimen_JP",
            "kitAssembly_JP",
            "cancerOccurrence_JP",
            "bioSurvey_v1_JP",
            "clinicalBioSurvey_v1_JP",
            "covid19Survey_v1_JP",
            "menstrualSurvey_v1_JP",
            "module1_v1_JP",
            "module1_v2_JP",
            "module2_v1_JP",
            "module2_v2_JP",
            "module3_v1_JP",
            "module4_v1_JP",
            "mouthwash_v1_JP",
            "promis_v1_JP")

# Initialize an empty dataframe to store counts
biospec_kit_cancer_counts_df <- data.frame(
  Table = character(),
  Connect_ID = character(),
  Non_Null_Count = integer(),
  Null_Count = integer(),
  stringsAsFactors = FALSE
)

# Loop through each table
for (table in tables) {
  # Construct the SQL query to pull all data for the specified Connect_IDs
  sql_query <- sprintf(
    "SELECT *
     FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.%s`
     WHERE Connect_ID IN (%s)",
    table, paste(sprintf("'%s'", connect_ids$Connect_ID), collapse = ", ")
  )
  
  
  # Run the query and download the data
  query_job <- bq_project_query(project_id, sql_query)
  data <- bq_table_download(query_job, bigint = "integer64")
  
  # Ensure entry is created even if there's no data
  connect_data <- if (!is.null(data) && nrow(data) > 0) data else data.frame()
  
  # Count non-null and null values
  non_null_count <- sum(!is.na(connect_data))
  null_count <- sum(is.na(connect_data))
  
  # Store the result in the dataframe
  biospec_kit_cancer_counts_df <- rbind(biospec_kit_cancer_counts_df, data.frame(
    Table = table,
    Connect_ID = connect_ids$Connect_ID,
    Non_Null_Count = non_null_count,
    Null_Count = null_count,
    stringsAsFactors = FALSE
  ))
  
}

# Print the dataframe with counts
print(biospec_kit_cancer_counts_df)





#notification table

# Query to get tokens for the given Connect_IDs
tokens_query <- sprintf(
  "SELECT Connect_ID, token
   FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP`
   WHERE Connect_ID IN (%s)",
  paste(sprintf("'%s'", connect_ids$Connect_ID), collapse = ", ")
)

# Run the query to get tokens
tokens_job <- bq_project_query(project_id, tokens_query)
tokens_data <- bq_table_download(tokens_job, bigint = "integer64")


# Extract the list of tokens
tokens_list <- tokens_data$token

# List of tables to check with tokens
token_tables <- c("notifications_JP")


notification_counts_df <- data.frame(
  Table = rep("notifications", 1),
  Connect_ID = rep("", 1),
  Non_Null_Count = rep(0, 1),
  Null_Count = rep(0,1),
  stringsAsFactors = FALSE
)
# Function to count non-null and null values in token-based tables
#manually find the token 
count_nulls_non_nulls_tokens <- function(table, tokens) {
  # Construct the SQL query to pull all data for the specified tokens
  sql_query <- sprintf("SELECT * FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.notifications_JP` WHERE token IN (%s)", paste(sprintf("'%s'", token), collapse = ", "))
  
  
  # Run the query and download the data
  query_job <- bq_project_query(project_id, sql_query)
  data <- bq_table_download(query_job, bigint = "integer64")
  
  
  # Ensure entry for each token even if there's no data
  for (t in tokens) {
    # Subset the data for the current token
    token_data <- if (!is.null(data)) data %>% filter(token == t) else data.frame()
    
    # Count non-null and null values
    non_null_count <- sum(!is.na(token_data))
    null_count <- sum(is.na(token_data))
    
    # Store the result in the dataframe
    notification_counts_df <<- rbind(notification_counts_df, data.frame(
      Table = table,
      Connect_ID = t,
      Non_Null_Count = non_null_count,
      Null_Count = null_count,
      stringsAsFactors = FALSE
    ))
  }
}

# Loop through each token-based table and count nulls/non-nulls
for (table in token_tables) {
  count_nulls_non_nulls_tokens(table, tokens_list)
}



all_counts <- rbind(biospec_kit_cancer_counts_df, notification_counts_df)


addWorksheet(wb2, "query2_all_table_counts")
writeData(wb2, "query2_all_table_counts", all_counts)



















##SSN counts
# Pull the entire participants table for the specified Connect_IDs
sql_query <- sprintf(
  "SELECT Connect_ID, d_126331570
   FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.participants_JP`
   WHERE Connect_ID IN (%s)",
  paste(sprintf("'%s'", connect_ids$Connect_ID), collapse = ", ")
)


# Run the query and download the data
query_job <- bq_project_query(project_id, sql_query)
participants_data <- bq_table_download(query_job, bigint = "integer64")


# Initialize an empty dataframe to store counts
ssn_counts_df <- data.frame(
  Table = integer(),
  Non_Null_Count = integer(),
  Null_Count = integer(),
  stringsAsFactors = FALSE
)

# Count null/non-null values for the specific variable
non_null_count <- sum(!is.na(participants_data$d_126331570))
null_count <- sum(is.na(participants_data$d_126331570))

# Store the result in the dataframe
ssn_counts_df <- rbind(ssn_counts_df, data.frame(
  Table = "d_126331570",
  Connect_ID = connect_ids$Connect_ID,
  Non_Null_Count = non_null_count,
  Null_Count = null_count,
  stringsAsFactors = FALSE
))

# Print the dataframe with counts
print(ssn_counts_df)



# Boxes
# boxes table links to connect_id in the following way:
# biospecimen -> collection id (d_820476880)
# boxes -> tubeid (remove last 4 digits of this value)

# Construct the SQL query to pull id and Connect_ID from biospecimen_JP table
sql_query <- sprintf(
  "SELECT d_820476880, Connect_ID
   FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.biospecimen_JP`
   WHERE Connect_ID IN (%s)",
  paste(sprintf("'%s'", connect_ids), collapse = ", ")
)

# Run the query and download the data
query_job <- bq_project_query(project_id, sql_query)
biospecimen_data <- bq_table_download(query_job, bigint = "integer64")

# Construct the SQL query to pull all data from boxes_JP table
sql_query <- "SELECT * FROM `nih-nci-dceg-connect-prod-6d04.FlatConnect.boxes_JP`"

# Run the query and download the data
query_job <- bq_project_query(project_id, sql_query)
boxes_data <- bq_table_download(query_job, bigint = "integer64")

# Strip the last 4 characters and a space from tubeID in boxes_data
boxes_data <- boxes_data %>%
  mutate(tubeID = ifelse(nchar(tubeID) > 5, substr(tubeID, 1, nchar(tubeID) - 5), tubeID))

# Merge boxes_data with biospecimen_data using tubeID and d_820476880
merged_data <- merge(boxes_data, biospecimen_data, by.x = "tubeID", by.y = "d_820476880", all = TRUE)

# Keep only the data destruction associated Connect_IDs
filtered_merged_data <- merged_data %>% filter(Connect_ID %in% connect_ids)

# Initialize an empty dataframe to store counts
boxes_counts_df <- data.frame(
  Table = character(),
  Connect_ID = character(),
  Non_Null_Count = integer(),
  Null_Count = integer(),
  stringsAsFactors = FALSE
)


  # Count non-null and null values
  non_null_count <- sum(!is.na(filtered_merged_data))
  null_count <- sum(is.na(filtered_merged_data))
  
  # Store the result in the dataframe
  boxes_counts_df <- rbind(boxes_counts_df, data.frame(
    Table = "boxes_JP",
    Connect_ID = connect_id,
    Non_Null_Count = non_null_count,
    Null_Count = null_count,
    stringsAsFactors = FALSE
  ))

# Print the dataframe with counts
print(boxes_counts_df)


ssn_boxes_counts <- rbind(ssn_counts_df, boxes_counts_df)

addWorksheet(wb2, "query3_ssn_boxes")
writeData(wb2, "query3_ssn_boxes", ssn_boxes_counts)

# Save the workbook to a file
saveWorkbook(wb2, filename, overwrite = TRUE)








