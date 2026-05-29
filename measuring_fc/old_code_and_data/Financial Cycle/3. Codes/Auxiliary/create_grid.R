# Create grid for values of c and gamma
create_grid <- function(obstime,trim) {
  s <- as.data.frame(obstime)
  s$index <- 1:length(obstime)
  interv.s <- quantile(s$index, c(trim, 1-trim))
  grid <- s[s$index>interv.s[1] & s$index<interv.s[2],]
  grid[,1] <- as.character(grid[,1])
  colnames(grid) <- c("obstime","index")
  return(grid)
}