getauroc <- function(data,y,x, theta = 0.5){
  
  glm_model <- glm(data[,y] ~ data[,x], family = binomial(link = "logit"), data = data)
  glm_pred <- predict(glm_model,type="response")
  glm_roc <- roc(data[,y] ~ glm_pred, plot = FALSE, print.auc = FALSE, quiet=TRUE)
  
  # Get all thresholds, sensitivities, and specificities
  roc_coords <- coords(glm_roc, "all", ret = c("threshold", "sensitivity", "specificity"), transpose = FALSE)
  thresholds <- roc_coords[, "threshold"]
  sensitivities <- roc_coords[, "sensitivity"]
  specificities <- roc_coords[, "specificity"]
  
  # T1 = type I error = failing to signal a crisis (false negative = 1 - sensitivity)
  # T2 = type II error = false alarm (false positive = 1 - specificity)
  # Paper convention: L = theta * T1 + (1 - theta) * T2
  type_i_errors  <- as.matrix(1 - sensitivities)   # missed crisis rate (T1)
  type_ii_errors <- as.matrix(1 - specificities)   # false alarm rate (T2)

  names(type_i_errors)  <- "type_i_errors"
  names(type_ii_errors) <- "type_ii_errors"

  # Compute loss and usefulness for each threshold
  losses <- theta * type_i_errors + (1 - theta) * type_ii_errors
  usefulnesses <- pmin(theta, 1 - theta) - losses
  
  names(losses) <- "losses" 
  names(usefulnesses) <- "usefulnesses"
  
  # Find the threshold that maximizes usefulness
  max_usefulness_index <- which.max(usefulnesses)
  max_usefulness_threshold <- thresholds[max_usefulness_index]
  max_usefulness <- usefulnesses[max_usefulness_index]
  type_i_error_at_max <- type_i_errors[max_usefulness_index]
  type_ii_error_at_max <- type_ii_errors[max_usefulness_index]
  
  out <- list(
    auroc = glm_roc$auc,
    usefulness = max_usefulness,
    max_usefulness_threshold = max_usefulness_threshold,
    type_i_error_at_max = type_i_error_at_max,
    type_ii_error_at_max = type_ii_error_at_max
  )
  
  return(out)  
  
}