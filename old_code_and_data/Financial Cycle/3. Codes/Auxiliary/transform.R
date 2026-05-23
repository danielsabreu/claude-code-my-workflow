library(dplyr)
library(stringr)

transform <- function(x) {
  
  col_names <- colnames(x)
  out <- data.frame(x$obstime)
  colnames(out) <- "obstime"
  
  for(i in 2:ncol(x)) {
    
    yy <- na.omit(x[,c(1,i)]) %>% 
      mutate(
        yy.roc.1y = .data[[col_names[i]]] / lag(.data[[col_names[i]]], 4) - 1,
        yy.roc.2y = .data[[col_names[i]]] / lag(.data[[col_names[i]]], 8) - 1,
        yy.roc.3y = .data[[col_names[i]]] / lag(.data[[col_names[i]]], 12) - 1,
        yy.dif.1y = .data[[col_names[i]]] - lag(.data[[col_names[i]]], 4),
        yy.dif.2y = .data[[col_names[i]]] - lag(.data[[col_names[i]]], 8),
        yy.dif.3y = .data[[col_names[i]]] - lag(.data[[col_names[i]]], 12),
        yy.lag.1 = lag(.data[[col_names[i]]], 1),
        yy.lag.2 = lag(.data[[col_names[i]]], 2),
        yy.lag.3 = lag(.data[[col_names[i]]], 3))
    new_col_names <- str_replace(colnames(yy)[-1], 'yy', paste0(col_names[i]))
    colnames(yy)[-1] <- new_col_names
    
    out <- left_join(out, yy, by = "obstime")
    
  }
  
  return(out)
  
}