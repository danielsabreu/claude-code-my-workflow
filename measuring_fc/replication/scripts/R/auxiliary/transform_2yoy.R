library(dplyr)
library(stringr)
library(zoo)

transform_2yoy <- function(x) {
  
  col_names <- colnames(x)
  out <- data.frame(x$obstime)
  colnames(out) <- "obstime"
  
  for (i in 2:ncol(x)) {
    
    # Calculate the year-on-year rate of change (yy.roc.2yoy)
    yy <- na.omit(x[, c(1, i)]) %>%
      mutate(yy.roc.2yoy = .data[[col_names[i]]] / lag(.data[[col_names[i]]], 8) - 1)
    
    # Replace infinite values in yy.roc.2yoy with the previous observation
    yy <- yy %>%
      mutate(yy.roc.2yoy = ifelse(is.infinite(yy.roc.2yoy), NA, yy.roc.2yoy)) %>%
      mutate(yy.roc.2yoy = na.locf(yy.roc.2yoy, na.rm = FALSE))
    
    # Rename new columns by replacing 'yy' with the actual column name
    new_col_names <- str_replace(colnames(yy)[-1], 'yy', paste0(col_names[i]))
    colnames(yy)[-1] <- new_col_names
    
    # Join the new data frame with the output data frame
    out <- left_join(out, yy, by = "obstime")
    
  }
  
  out <- out[, !colnames(out) %in% col_names[-1]]
  return(out)
  
}
