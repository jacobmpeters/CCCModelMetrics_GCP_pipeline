# CCC Module Metrics API

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
weekly_module_metrics:
  rmd_file_name: "CCC Weekly Module Metrics_RMD.Rmd"
  report_file_name: "CCC_Weekly_Module_Metrics.pdf"
  box_folders:
    - "183922736204" # internal
    - "141543281606" # sites can view this one
  cadence: "every Monday"

mod1_stats:
  rmd_file_name: "Merged Module 1 Summary Statistics.Rmd"
  report_file_name: "Merged_Module_1_Summary_Statistics.pdf"
  box_folders:
    - "208053733985"
  cadence: "1st of the month"

mod2_stats:
  rmd_file_name: "Merged Module 2 Summary Statistics.Rmd"
  report_file_name: "Merged_Module_2_Summary_Statistics.pdf"
  box_folders:
    - "208055378225"
  cadence: "1st of the month"

mod3_stats:
  rmd_file_name: "Module 3 Summary Statatistics.Rmd"
  report_file_name: "Module_3_Summary_Statatistics.pdf"
  box_folders:
    - "208062917930"
  cadence: "1st of the month"

mod4_stats:
  rmd_file_name: "Module 4 Missingness Analysis.Rmd"
  report_file_name: "Module_4_Missingness_Analysis.pdf"
  box_folders:
    - "208060974530"
  cadence: "1st of the month"

baseline_high_priority:
  rmd_file_name: "Baseline Ranked Variables- High Priority.Rmd"
  report_file_name: "Baseline_Ranked_Varialbes_High_Priority.pdf"
  box_folders:
    - "219595986209"
  cadence: "1st of the month"

baseline_low_priority:
  rmd_file_name: "Baseline Ranked Variables- Low Priority.Rmd"
  report_file_name: "Baseline_Ranked_Variables_Low_Priority.pdf"
  box_folders:
    - "219761433401"
  cadence: "1st of the month"

```

## Running the API with Google Cloud Run and Cloud Scheduler

To deploy the API, you can use Google Cloud Run and schedule API requests using Cloud Scheduler. Here's a basic outline of the process:

1. **Containerize the API**: Build a Docker container with your API script and its dependencies.

2. **Push to Container Registry**: Push the Docker container image to Google Container Registry.

3. **Deploy to Cloud Run**: Deploy the container image to Google Cloud Run and configure the necessary environment variables.

4. **Schedule API Requests**: Use Google Cloud Scheduler to schedule API requests by specifying the API endpoint URL and desired frequency.

5. **Authenticate with Google Cloud**: Ensure proper authentication between the services.

