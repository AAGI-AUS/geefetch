# Prevent R CMD check NOTEs for data.table NSE variables
# Add column names used in data.table operations as they arise
utils::globalVariables(c(
  ".",
  ".SD",
  "alias",
  "collection",
  "description",
  "domain",
  "resolution",
  "temporal"
))
