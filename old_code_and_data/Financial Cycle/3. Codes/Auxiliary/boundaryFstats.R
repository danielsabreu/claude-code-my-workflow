boundary.Fstats <- function(x, alpha = 0.05, pval = FALSE, aveF =
                              FALSE, asymptotic = FALSE, ...)
{
  if(aveF)
  {
    myfun <-  function(y) {pvalue.Fstats(y, type="ave", x$nreg, x$par) - alpha}
    upper <- 40
  }
  else
  {
    myfun <-  function(y) {pvalue.Fstats(y, type="sup", x$nreg, x$par) - alpha}
    upper <- 80
  }
  bound <- uniroot(myfun, c(0,upper))$root
  if(pval)
  {
    if(asymptotic)
      bound <- 1 - pchisq(bound, x$nreg)
    else
      bound <- 1 - pf(bound, x$nreg, (x$nobs-2*x$nreg))
  }
  bound <- ts(bound,
              start = start(x$Fstats),
              end = end(x$Fstats),
              frequency = frequency(x$Fstats))
  return(bound)
}