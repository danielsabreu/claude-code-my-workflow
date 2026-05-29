BW_filter <- function(df, bw_freq=12, bw_nfix=2, drift = FALSE) {
  # Add a new observation (t+1) with last observation values
  obstime <- as.Date(df[nrow(df), 1]) %m+% months(3)
  df_bw <- rbind(df, cbind(obstime, df[nrow(df), 2:ncol(df)]))
  print("passou")
  # Perform first Butterworth filter to remove cycles above bw_freq
  df_cycle_1 <- getfilter(df_bw, filter = "BW", freq = bw_freq, nfix = bw_nfix, drift = drift)$cycle
  
  # Second Butterworth filter to clean trend from cycles below bw_freq/2
  df_cycle_2 <- getfilter(df_cycle_1, filter = "BW", freq = bw_freq / 2, nfix = bw_nfix + 2, drift = drift)$trend

  # Return the filtered cycle data frame
  return(df_cycle_2[-nrow(df_cycle_2), ])
}