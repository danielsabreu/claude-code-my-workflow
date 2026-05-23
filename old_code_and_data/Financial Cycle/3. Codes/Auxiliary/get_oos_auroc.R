get_oos_auroc <- function(data, y, x, start_date, end_date, lag_years = 1) {
  
  data$obstime <- as.Date(data$obstime)
  data <- data[order(data$obstime), ]

  auroc_oos <- numeric()
  
  for (quarter in seq(as.Date(start_date), as.Date(end_date), by = "quarter")) {
    
    # Define the end of the training period (lag_years before the quarter)
    train_end <- quarter - years(lag_years)
    
    # Split data into training and testing sets
    train_data <- data[data$obstime <= train_end, ]
    test_data <- data[data$obstime == quarter, ]

    # Estimate logit and compute auroc for the test quarter
    glm_model <- glm(train_data[[y]] ~ train_data[[x]], family = binomial(link = "logit"), data = train_data)
    glm_pred <- predict(glm_model, newdata = test_data, type = "response")
    glm_roc <- roc(test_data[[y]] ~ glm_pred, plot = FALSE, print.auc = FALSE, quiet = TRUE)
    auroc_oos <- c(auroc_oos, glm_roc$auc)
  }
  
  return(auroc_oos)
}