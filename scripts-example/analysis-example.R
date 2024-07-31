# Load libraries
# pak::pak("gnoblet/impactR.kobo")
library(impactR.kobo)
# pak::pak("impact-initiatives-hppu/humind")
library(impactR.analysis)
library(srvyr)

# First, let's source the compose.R file
# - it loads needed data
# - it composes the needed new column
source("scripts-example/compose-example.R")

# Note that there are warnings that are fixed in v2024.1.1 (see https://github.com/impact-initiatives-hppu/humind/tree/dev2024.1.1)

# Analysis groups ---------------------------------------------------------

# List of grouping variables
group_vars <- list("admin1", "hoh_gender", "hoh_age_cat")
# Here you can add in group_vars the variable you want to disaggregate by
# Following your data disagregation plan, see MSNI guidance for more information

# Add this list of variables to loop (including weights, and stratum if relevant), joining by uuid
# and removing columns existing in both
loop <- df_diff(loop, main, uuid) |>
  left_join(
    main |> select(uuid, weight, !!!unlist(group_vars)),
    by = "uuid"
  )


# Prepare design and kobo -------------------------------------------------

# Design main - weighted
design_main_w <- main |>
  as_survey_design(weight = weight)

# Design loop - weighted
design_loop_w <- loop |>
  as_survey_design(weight = weight)

# Survey - one column must be named label 
# and the type column must be split into type and list_name
survey <- survey_updated |>
  split_survey(type) |>
  rename(label = label_english)

# Choices - one column must be named label
choices <- choices_updated |>
  rename(label = label_english)



# Prepare analysis --------------------------------------------------------

# Load list of analysis (example is in humind.data::loa)
loa_main <- loa |> filter(dataset == "main")
loa_loop <- loa |> filter(dataset == "loop")

# Run analysis ------------------------------------------------------------


# Main analysis - weighted
if (nrow(loa_main_w) > 0) {
  an_main_w <- impactR.analysis::kobo_analysis_from_dap_group(
    design_main_w,
    loa_main_w,
    survey,
    choices,
    l_group = group_vars,
    choices_sep = "/")
} else {
  an_main_w <- tibble()
}

# Main analysis - unweighted
if (nrow(loa_main_unw) > 0) {
  an_main_unw <- impactR.analysis::kobo_analysis_from_dap_group(
    design_main_unw,
    loa_main_unw,
    survey,
    choices,
    l_group = group_vars,
    choices_sep = "/")
} else {
  an_main_unw <- tibble()
}

# Loop analysis - weighted
if (nrow(loa_loop_w) > 0) {
  an_loop_w <- impactR.analysis::kobo_analysis_from_dap_group(
    design_loop_w,
    loa_loop_w,
    survey,
    choices,
    l_group = group_vars,
    choices_sep = "/")
} else {
  an_loop_w <- tibble()
}

# Loop analysis - unweighted
if (nrow(loa_loop_unw) > 0) {
  an_loop_unw <- impactR.analysis::kobo_analysis_from_dap(
    design_loop_unw,
    loa_loop_unw,
    survey,
    choices,
    l_group = group_vars,
    choices_sep = "/")
} else {
  an_loop_unw <- tibble()
}


# Bind all, view, and save ------------------------------------------------

# Bind all
an <- bind_rows(an_main_w, an_main_unw, an_loop_w, an_loop_unw)
