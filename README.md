
<!-- README.md is generated from README.Rmd. Please edit that file -->

# emdash.rules

## Fit models using a Targets workflow

``` r
library(targets)
library(tidymodels)
```

``` r
tar_make()
#> -\|[32m✔[39m skip target my_control
#> /[32m✔[39m skip target my_spec_dtree
#> -[32m✔[39m skip target my_spec_rf
#> \[32m✔[39m skip target participants
#> |[32m✔[39m skip target my_metrics
#> /[32m✔[39m skip target model_data
#> -[32m✔[39m skip target my_recipe
#> \[32m✔[39m skip target my_folds
#> |[32m✔[39m skip target baked_model_data
#> /[32m✔[39m skip target my_workflows
#> -[32m✔[39m skip target my_tuned_workflows
#> \[32m✔[39m skip pipeline
#> |Warning message:
#> In readLines(script) : incomplete final line found on '_targets.R'
#> /- 
tar_load(my_tuned_workflows)
tar_load(baked_model_data)
```

![](man/figures/targets-workflow.png)

``` r
head(baked_model_data)
#> # A tibble: 6 x 7
#>   android_i_os version_major version_minor version_patch last_communication_elaps… last_data_upload_elaps… status  
#>   <fct>        <fct>         <fct>         <fct>                             <dbl>                   <dbl> <fct>   
#> 1 unknown      unknown       unknown       unknown                          -1                      -1     check t…
#> 2 android      10            0             0                                 0.716                   0.882 unknown 
#> 3 ios          14            3             0                                 0.826                   0.874 unknown 
#> 4 android      7             1             1                                 0.733                   0.899 unknown 
#> 5 unknown      unknown       unknown       unknown                          -1                      -1     check t…
#> 6 unknown      unknown       unknown       unknown                          -1                      -1     check t…
autoplot(my_tuned_workflows) + theme_light(base_family = "IBMPlexSans")
```

<img src="man/figures/README-plot-metrics-1.png" width="100%" />
