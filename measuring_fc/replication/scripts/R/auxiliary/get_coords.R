library(pROC)

get_coords <- function(data, y, x, theta) {
  
  # Fit logistic regression to calculate predicted probabilities
  glm_model <- glm(data[[y]] ~ data[[x]], family = binomial(link = "logit"), data = data)
  pred_probs <- predict(glm_model, type = "response")
  
  # Generate the ROC curve object
  roc_obj <- roc(data[[y]], pred_probs)
  
  # Get all thresholds, sensitivities, and specificities
  thresholds <- coords(roc_obj, "all", ret = "threshold", transpose = FALSE)
  sensitivities <- coords(roc_obj, "all", ret = "sensitivity", transpose = FALSE)
  specificities <- coords(roc_obj, "all", ret = "specificity", transpose = FALSE)
  
  # T1 = type I error = failing to signal a crisis (false negative = 1 - sensitivity)
  # T2 = type II error = false alarm (false positive = 1 - specificity)
  # Paper convention: L = theta * T1 + (1 - theta) * T2
  type_i_errors  <- as.matrix(1 - sensitivities)   # missed crisis rate (T1)
  type_ii_errors <- as.matrix(1 - specificities)   # false alarm rate (T2)

  names(type_i_errors)  <- "type_i_errors"
  names(type_ii_errors) <- "type_ii_errors"

  # Compute loss and usefulness for each threshold
  losses <- theta * type_i_errors + (1 - theta) * type_ii_errors
  usefulnesses <- min(theta, 1 - theta) - losses
  
  names(losses) <- "losses" 
  names(usefulnesses) <- "usefulnesses"
  
  # Find the threshold that maximizes usefulness
  max_usefulness_index <- which.max(usefulnesses)
  max_usefulness_threshold <- thresholds[max_usefulness_index, ]
  max_usefulness <- usefulnesses[max_usefulness_index]
  type_i_error_at_max <- type_i_errors[max_usefulness_index]
  type_ii_error_at_max <- type_ii_errors[max_usefulness_index]
  
  # Combine results into a dataframe
  results <- data.frame(
    threshold = thresholds,
    type_i_error = type_i_errors,
    type_ii_error = type_ii_errors,
    loss = losses,
    usefulness = usefulnesses
  )
  
  # Add a list containing optimal threshold details
  output <- list(
    all_thresholds = results,
    optimal_threshold = list(
      threshold = max_usefulness_threshold,
      type_i_error = type_i_error_at_max,
      type_ii_error = type_ii_error_at_max,
      usefulness = max_usefulness
    )
  )
  
  return(output)
}
