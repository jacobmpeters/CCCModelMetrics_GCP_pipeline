# CCC Module Metrics API

This repository contains an R script that generates a Plumber API for running and rendering Kelsey's Rmarkdown files. The API is designed to run various module metrics reports based on the specified parameters.

## Author

- Author: Jake Peters
- Date: October 2022

## Introduction

This script provides a Plumber API to run and render Kelsey's Rmarkdown files. The API can be used to generate module metrics reports with customizable parameters.

## Dependencies

The script requires the following R packages:

- plumber
- rmarkdown
- googleCloudStorageR
- gargle
- tools
- config

## Endpoints

### Heartbeat

- **Method**: GET, POST
- **Route**: `/`
- **Description**: Returns "alive" for testing purposes.

### Run Module Analytics

- **Method**: GET, POST
- **Route**: `/run-module-analytics`
- **Description**: Runs Kelsey's markdown file with the specified report and testing parameters. Renders the Rmarkdown file, uploads the report to Google Cloud Storage, and returns a message indicating completion.

#### Parameters

- `report`: Which report to run.
- `testing`: Whether we're testing or not.

## Configuration

The configuration for the API and reports is stored in the `config.yaml` file. Here are the default and report-specific configurations:

### Default Configuration

- Report Maintainer: Kelsey Dowling
- Pipeline Maintainer: Jake Peters
- Bucket: gs://ccc_weekly_metrics_report
- Test Box Folders: 
  - "123456789012"

### Weekly Module Metrics

- RMD File Name: "CCC Weekly Module Metrics_RMD.Rmd"
- Report File Name: "CCC_Weekly_Module_Metrics.pdf"
- Box Folders: 
  - "183922736204" (internal)
  - "141543281606" (sites can view this one)
- Cadence: every Monday

### Module 1 Stats

- RMD File Name: "Merged Module 1 Summary Statistics.Rmd"
- Report File Name: "Merged_Module_1_Summary_Statistics.pdf"
- Box Folders: 
  - "208053733985"
- Cadence: 1st of the month

### Module 2 Stats

- RMD File Name: "Merged Module 2 Summary Statistics.Rmd"
- Report File Name: "Merged_Module_2_Summary_Statistics.pdf"
- Box Folders: 
  - "208055378225"
- Cadence: 1st of the month

### Module 3 Stats

- RMD File Name: "Module 3 Summary Statatistics.Rmd"
- Report File Name: "Module_3_Summary_Statatistics.pdf"
- Box Folders: 
  - "208062917930"
- Cadence: 1st of the month

### Module 4 Stats

- RMD File Name: "Module 4 Missingness Analysis.Rmd"
- Report File Name: "Module_4_Missingness_Analysis.pdf"
- Box Folders: 
  - "208060974530"
- Cadence: 1st of the month

### Baseline High Priority

- RMD File Name: "Baseline Ranked Variables- High Priority.Rmd"
- Report File Name: "Baseline_Ranked_Varialbes_High_Priority.pdf"
- Box Folders: 
  - "219595986209"
- Cadence: 1st of the month

### Baseline Low Priority

- RMD File Name: "Module 4 Missingness Analysis.Rmd"
- Report File Name: "Module_4_Missingness_Analysis.pdf"
- Box Folders: 
  - "219761433401"
- Cadence: 1st of the month

