FROM rocker/r-ver:4.6.1

# System libraries needed by geefetch's spatial stack (sf, terra) and
# HTTP stack (httr2, curl) + doc tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libssl-dev libxml2-dev libcurl4-openssl-dev libgit2-dev \
      libgdal-dev libproj-dev libgeos-dev libudunits2-dev \
      libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
      libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
      pandoc git sudo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG USERNAME=rstudio
ARG USER_UID=1000
RUN useradd --uid $USER_UID -m -s /bin/bash $USERNAME

USER $USERNAME
WORKDIR /workspaces/geefetch

# Pre-install the dev toolchain so postCreateCommand (which runs
# pak::local_install_dev_deps() against geefetch/DESCRIPTION) is fast.
RUN R -e "install.packages(c('pak','devtools','languageserver','httptest2','lifecycle','cffr','codemetar','lintr','roxygen2'), \
          repos = 'https://packagemanager.posit.co/cran/__linux__/jammy/latest')"
