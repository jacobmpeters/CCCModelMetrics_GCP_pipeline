# Dockerfile

FROM rocker/tidyverse:latest

# Set the correct path for xelatex
ENV PATH="$PATH:/root/bin:/usr/local/lib"
# Message daniel on gitter when this doesn't work

# Install tinytex linux dependencies, pandoc, and rmarkdown
# Reference: https://github.com/csdaw/rmarkdown-tinytex/blob/master/Dockerfile
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    wget \
    graphviz \ 
    imagemagick \
    perl && \
    /rocker_scripts/install_pandoc.sh && \
    install2.r rmarkdown 

# Install tinytex
# RUN Rscript -e 'tinytex::install_tinytex()'
RUN Rscript -e 'tinytex::install_tinytex(repository = "illinois")'

# Install R libraries
RUN install2.r --error plumber bigrquery dplyr googleCloudStorageR gargle \
               tools epiDisplay lubridate tidyverse knitr gtsummary tidyr \
               googleCloudStorageR reshape gmodels lubridate config magick \
               foreach arsenal rio gridExtra scales data.table listr sqldf \
               expss gmodels magrittr naniar UpSetR RColorBrewer ggrepel \
               ggmap maps mapdata Rcpp rgdal sf zipcodeR viridis ggthemes usmap
              
# These libraries might not be available from install2.R so use CRAN
RUN R -e "install.packages(c('gt', 'vtable', 'pdftools', 'sf'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

# When I try to use kable extra with a normal installation from CRAN or install2.r
# I get the error:
# Error: package or namespace load failed for 'kableExtra':
# .onLoad failed in loadNamespace() for 'kableExtra', details:
#  call: !is.null(rmarkdown::metadata$output) && rmarkdown::metadata$output %in% 
#  error: 'length = 2' in coercion to 'logical(1)'
# The solution is to install a patched version from github
# https://github.com/haozhu233/kableExtra/issues/750
RUN R -e "devtools::install_github('kupietz/kableExtra')"

# Copy R code to directory in instance
COPY ["./ccc_module_metrics_api.R", "./ccc_module_metrics_api.R"]
COPY ["./config.yml", "./config.yml"]
COPY ["./CCC Weekly Module Metrics_RMD.Rmd", "./CCC Weekly Module Metrics_RMD.Rmd"]
COPY ["./Baseline Ranked Variables- High Priority.Rmd", "./Baseline Ranked Variables- High Priority.Rmd"]
COPY ["./Baseline Ranked Variables- Low Priority.Rmd", "./Baseline Ranked Variables- Low Priority.Rmd"]
COPY ["./Merged Module 1 Summary Statistics.Rmd", "./Merged Module 1 Summary Statistics.Rmd"]
COPY ["./Merged Module 2 Summary Statistics.Rmd", "./Merged Module 2 Summary Statistics.Rmd"]
COPY ["./Module 3 Summary Statatistics.Rmd", "./Module 3 Summary Statatistics.Rmd"]
COPY ["./Module 4 Missingness Analysis.Rmd", "./Module 4 Missingness Analysis.Rmd"]
COPY ["./zip_to_lat_lon_North_America.csv", "./zip_to_lat_lon_North_America.csv"]


# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('ccc_module_metrics_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
