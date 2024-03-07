# CCC Module Metrics API

# test
This repository contains an R script that generates a Plumber API for running and rendering Kelsey's Rmarkdown files. The API is designed to run various module metrics reports based on the specified parameters.

## Contributors

- Pipeline Developer: Jake Peters
- Date: October 2022
- Modified: August 2023

- Report Developer: Kelsey Dowling

## Introduction

The ccc_module_metrics_api.R script provides a Plumber API to run and render Kelsey's Rmarkdown files. The API can be used to generate module metrics reports with customizable parameters.

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

The configuration for the API and reports is stored in the [`config.yml`](config.yml) file. The `config.yml` file contains various parameters for different reports, including RMD file names, report file names, box folders, and cadence.

```yaml
default:
  report_maintainer: "Kelsey Dowling"
  pipeline_maintainer: "Jake Peters"
  bucket: "gs://ccc_weekly_metrics_report"
  test_box_folders: 
    - "222593912729"
  gcp_info:
    cloud_build_trigger: ccc-module-metrics
    cloud_run: ccc-module-metrics-api

weekly_module_metrics:
  rmd_file_name: "CCC Weekly Module Metrics_RMD.Rmd"
  report_file_name: "CCC_Weekly_Module_Metrics.pdf"
  box_folders:
    - "183922736204" # internal
  gcp_info:
    cloud_scheduler: ccc-weekly-module-metrics
    frequency: "0 11 * * 1" # every Monday at 11 AM"

mod1_stats:
  rmd_file_name: "Merged Module 1 Summary Statistics.Rmd"
  report_file_name: "Merged_Module_1_Summary_Statistics.pdf"
  box_folders:
    - "208053733985"
  gcp_info:
    cloud_scheduler: ccc-module1-statistics
    frequency: "30 11 1 * *" # first of the month at 11:30 AM

mod2_stats:
  rmd_file_name: "Merged Module 2 Summary Statistics.Rmd"
  report_file_name: "Merged_Module_2_Summary_Statistics.pdf"
  box_folders:
    - "208055378225"
  gcp_info:
    cloud_scheduler: ccc-module2-statistics
    frequency: "0 12 1 * *" # first of the month at 12 PM

mod3_stats:
  rmd_file_name: "Module 3 Summary Statatistics.Rmd"
  report_file_name: "Module_3_Summary_Statatistics.pdf"
  box_folders:
    - "208062917930"
  gcp_info:
    cloud_scheduler: ccc-module3-statistics
    frequency: "30 12 1 * *" # first of the month at 12:30 PM

mod4_stats:
  rmd_file_name: "Module 4 Missingness Analysis.Rmd"
  report_file_name: "Module_4_Missingness_Analysis.pdf"
  box_folders:
    - "208060974530"
  gcp_info:
    cloud_scheduler: ccc-module4-statistics
    frequency: "0 13 1 * *" # first of the month at 1 PM

baseline_high_priority:
  rmd_file_name: "Baseline Ranked Variables- High Priority.Rmd"
  report_file_name: "Baseline_Ranked_Varialbes_High_Priority.pdf"
  box_folders:
    - "219595986209"
  gcp_info:
    cloud_scheduler: ccc-baseline-ranked-variables-high-priority
    frequency: "30 13 1 * *" # first of the month at 1:30 PM

baseline_low_priority:
  rmd_file_name: "Baseline Ranked Variables- Low Priority.Rmd"
  report_file_name: "Baseline_Ranked_Variables_Low_Priority.pdf"
  box_folders:
    - "219761433401"
  gcp_info:
    cloud_scheduler: ccc-baseline-ranked-variables-low-priority
    frequency: "30 14 1 * *" # first of the month at 2:30 PM
```

## Running the API with Google Cloud Run and Cloud Scheduler

To deploy the API, you can use Google Cloud Run and schedule API requests using Cloud Scheduler. Here's a basic outline of the process:

1. **Containerize the API**: Build a Docker container with your API script and its dependencies.

2. **Push to Container Registry**: Push the Docker container image to Google Container Registry.

3. **Deploy to Cloud Run**: Deploy the container image to Google Cloud Run and configure the necessary environment variables.

4. **Schedule API Requests**: Use Google Cloud Scheduler to schedule API requests by specifying the API endpoint URL and desired frequency.

5. **Authenticate with Google Cloud**: Ensure proper authentication between the services.

