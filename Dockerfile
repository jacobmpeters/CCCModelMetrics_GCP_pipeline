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
    
# Install dependencies for sf (used for Kelsey's mapping)
# Note that these dependencies and the Rcpp, rgdal and sf packages add a lot of
# time to the build. Remove them if not required for other reports.
#RUN apt-get -y update \
#  && apt-get install -y  \
#  libudunits2-dev \
#  libgdal-dev \
#  libgeos-dev \
#  libproj-dev
#RUN install.r --error maps mapdata zipcodeR viridis ggthemes usmap #Rcpp
#RUN R -e "install.packages(c('sf'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

              
# Install tinytex
# RUN Rscript -e 'tinytex::install_tinytex()'
RUN Rscript -e 'tinytex::install_tinytex(repository = "illinois")'

# Preinstall the LaTeX packages used by Rmarkdown and other PDF libraries
RUN Rscript -e 'tinytex::tlmgr_install(c("multirow", "ulem", "environ", "colortbl", "wrapfig", "pdflscape", "tabu", "threeparttable", "threeparttablex", "makecell"))'
# Alternatively, using tlmgr directly:
# RUN tlmgr install --repository=https://mirror.ctan.org/systems/texlive/tlnet multirow

# Install R libraries
RUN install2.r --error plumber bigrquery dplyr googleCloudStorageR gargle \
               tools epiDisplay lubridate tidyverse knitr gtsummary tidyr \
               googleCloudStorageR reshape gmodels lubridate config magick \
               foreach arsenal rio gridExtra scales data.table listr sqldf \
               expss gmodels magrittr naniar UpSetR RColorBrewer ggrepel 
               
# These libraries might not be available from install2.R so use CRAN
RUN R -e "install.packages(c('gt', 'vtable', 'pdftools'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

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
COPY ["./preamble.tex", "./preamble.tex"]
COPY ["./CCC Weekly Module Metrics_RMD.Rmd", "./CCC Weekly Module Metrics_RMD.Rmd"]
COPY ["./Baseline Ranked Variables- High Priority.Rmd", "./Baseline Ranked Variables- High Priority.Rmd"]
COPY ["./Baseline Ranked Variables- Low Priority.Rmd", "./Baseline Ranked Variables- Low Priority.Rmd"]
COPY ["./Merged Module 1 Summary Statistics.Rmd", "./Merged Module 1 Summary Statistics.Rmd"]
COPY ["./Merged Module 2 Summary Statistics.Rmd", "./Merged Module 2 Summary Statistics.Rmd"]
COPY ["./Module 3 Summary Statatistics.Rmd", "./Module 3 Summary Statatistics.Rmd"]
COPY ["./Module 4 Missingness Analysis.Rmd", "./Module 4 Missingness Analysis.Rmd"]
COPY ["./Rectruitment Derived Variable QC.Rmd", "./Rectruitment Derived Variable QC.Rmd"]
COPY ["./Module 1 Custom QC Rule Errors.Rmd", "./Module 1 Custom QC Rule Errors.Rmd"]
COPY ["./3 Month Quality of Life Survey Summary Statistics.Rmd" , "./3 Month Quality of Life Survey Summary Statistics.Rmd"]
COPY ["./Notifications QC.Rmd", "./Notifications QC.Rmd"]
COPY ["./Data Destruction CSV Output.R", "./Data Destruction CSV Output.R"]
COPY ["./PROMIS Completion vs Notifications.Rmd", "PROMIS Completion vs Notifications.Rmd"]
COPY ["./RCA Metrics.Rmd", "RCA Metrics.Rmd"]
COPY ["./RCA Custom QC.Rmd", "RCA Custom QC.Rmd"]
COPY ["./Module_2_Custom_QC.Rmd", "Module_2_Custom_QC.Rmd"]
COPY ["./Module_3_Custom_QC.Rmd", "Module_3_Custom_QC.Rmd"]



# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('ccc_module_metrics_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
