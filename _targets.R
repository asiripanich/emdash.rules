library(targets)
# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(summary) to view the results.

# Set target-specific options such as packages.
source("data-raw/tar_functions.R")
options(clustermq.scheduler = "multiprocess")
tar_option_set(
  packages = c("data.table", "magrittr", "tidymodels", "baguette", "janitor"),
  memory = "transient",
  garbage_collection = TRUE,
  storage = "worker"
)


# End this file with a list of target objects.
list(
  tar_target(
    participants,
    read.csv("data-raw/participants.csv") %>%
      as.data.table()
  ),
  tar_target(
    model_data,
    ingest_data(participants) %>%
      janitor::clean_names() %>%
      select(-last_trip_elapsed_time) %>%
      mutate(
        last_communication_elapsed_time = as.numeric(last_communication_elapsed_time),
        last_data_upload_elapsed_time = as.numeric(last_data_upload_elapsed_time),
        last_communication_elapsed_time = ifelse(is.na(last_communication_elapsed_time), -1, last_communication_elapsed_time),
        last_data_upload_elapsed_time = ifelse(is.na(last_data_upload_elapsed_time), -1, last_data_upload_elapsed_time),
        android_i_os_version = as.character(android_i_os_version),
        android_i_os_version = ifelse(android_i_os_version == "", "unknown.unknown.unknown", android_i_os_version)
      ) %>%
      separate(android_i_os_version, into = paste("version", c("major", "minor", "patch"), sep = "_")) %>%
      mutate(across(starts_with("version_"), ~ ifelse(is.na(.x), "0", .x)))
  ),
  tar_target(
    my_recipe,
    recipe(status ~ ., data = model_data) %>%
    step_factor2string(all_nominal())
  ),
  tar_target(
    baked_model_data, 
    my_recipe %>%
      prep() %>%
      bake(model_data)
  ),
  tar_target(
    my_spec_dtree,
    decision_tree(
      cost_complexity = tune(),
      tree_depth = tune(),
      min_n = tune()
      # levels = 4
    ) %>%
      set_engine("rpart") %>%
      set_mode("classification")
  ),
  tar_target(
    my_spec_rf,
    rand_forest(trees = tune(), mtry = tune(), min_n = tune()) %>%
      set_mode("classification") %>%
      set_engine("ranger", num.threads = 2)
  ),
  # tar_target(
  #   my_spec_mnl,
  #   multinom_reg(penalty = tune(), mixture = tune()) %>%
  #     set_mode("classification") %>%
  #     set_engine("glmnet")
  # ),
  tar_target(
    my_metrics,
    metric_set(mn_log_loss, accuracy, sensitivity, specificity, roc_auc)
  ),
  tar_target(
    my_folds,
    vfold_cv(model_data)
  ),
  tar_target(
    my_control,
    control_grid(
      save_pred = TRUE,
      parallel_over = "everything",
      save_workflow = FALSE
    )
  ),
  tar_target(
    my_workflows,
    workflow_set(
      preproc = list(rec = my_recipe),
      models = list(
        # mnl = my_spec_mnl,
        rf = my_spec_rf,
        dtree = my_spec_dtree
      )
    )
  ),
  tar_target(
    my_tuned_workflows,
    {
      doParallel::registerDoParallel()
      set.seed(20210717)
      workflow_map(
        my_workflows,
        seed = 1503,
        resamples = my_folds,
        grid = 25,
        control = my_control,
        verbose = TRUE,
        metrics = my_metrics
      )
    }
  )
)