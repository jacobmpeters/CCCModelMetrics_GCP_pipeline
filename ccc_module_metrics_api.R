# File:       ccc_module_metrics_api.R
# Decription: This script generates a plumber api that runs/renders Kelsey's 
#             Rmarkdown file.
# Author:     Jake Peters
# Date:       October 2022

library(plumber)
library(rmarkdown)
library(googleCloudStorageR)
library(gargle)
library(tools)
library(config)

#* heartbeat...for testing purposes only. Not required to run analysis.
#* @get /
#* @post /
function(){return("alive")}

#* Runs Kelsey's markdown file
#* @param report:str Which report to run 
#* @param testing:bool Whether we're testing or not
#* @get /run-module-metrics
#* @post /run-module-metrics
function(report, testing=FALSE){
  
  Sys.setenv(R_CONFIG_ACTIVE = report) # Determines which config from config.yml to use
  
  # Set parameters using arguments and config.yml file
  rmd_file_name    <- config::get(value="rmd_file_name")
  report_file_name <- config::get(value="report_file_name")
  bucket           <- config::get(value="bucket")
  if (testing) {
    box_folders <- config::get(value="test_box_folders")
  } else {
    box_folders <- config::get(value="box_folders")
  }
    
    # Add time stamp to report name
    report_fid <- paste0(file_path_sans_ext(report_file_name), 
                         format(Sys.time(), "_%m_%d_%Y"),
                         "_boxfolder_",box_folders,
                         ".", file_ext(report_file_name))
    
    # Select document type given the extension of the report file name
    output_format <- switch(file_ext(report_file_name),  
                            "pdf"  = "pdf_document",
                            "html" = "html_document") 
    if (is.null(output_format)) { 
      stop("Report file extension is invalid. Script did not execute.")}
    
    # Render the rmarkdown file
    rmarkdown::render(rmd_file_name, 
                      output_format = output_format,
                      output_file = report_fid, 
                      clean = TRUE)
    
    # Authenticate with Google Storage and write report file to bucket
    scope <- c("https://www.googleapis.com/auth/cloud-platform")
    token <- token_fetch(scopes=scope)
    gcs_auth(token=token)
    gcs_upload(report_fid, bucket=bucket, name=report_fid) 
    
    # Return a string for for API testing purposes
    ret_str <- paste("All done. Check", bucket, "for", report_fid)
    print(ret_str)
    return(ret_str) 
}
