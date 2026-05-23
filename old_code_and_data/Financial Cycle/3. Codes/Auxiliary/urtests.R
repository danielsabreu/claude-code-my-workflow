urtests <- function (x) {
  
  table.rejh0 <- matrix(NA,ncol(x),7)
  rownames(table.rejh0) <- colnames(x)
  colnames(table.rejh0) <- c("ADF_none","ADF_drift","ADF_trend","PP_drift","PP_trend","KPSS_mu","KPSS_tau")
  
  for (i in 1:ncol(x)) {
    
    #ADF
    xi <- na.omit(x[,1])
    
    df.none <- ur.df(xi,type="none",lags=8,selectlags="AIC")
    df.none.teststat <- df.none@teststat[[1]]
    df.none.rejh0 <- df.none.teststat<df.none@cval[2]
    
    df.drift <- ur.df(xi,type="drift",lags=8,selectlags="AIC")
    df.drift.teststat <- df.drift@teststat[[1]]
    df.drift.rejh0 <- df.drift.teststat<df.drift@cval[2]
    
    df.trend <- ur.df(xi,type="trend",lags=8,selectlags="AIC")
    df.trend.teststat <- df.trend@teststat[[1]]
    df.trend.rejh0 <- df.trend.teststat<df.trend@cval[2]
    
    #PP, uses same critical value as adf tests
    pp.drift <- ur.pp(xi,type="Z-alpha",model=c("constant"),lags = "long")
    pp.drift.teststat <- pp.drift@teststat
    pp.drift.rejh0 <- pp.drift.teststat<df.drift@cval[2]
    
    pp.trend <- ur.pp(xi,type="Z-alpha",model=c("constant","trend"),lags = "long")
    pp.trend.teststat <- pp.trend@teststat
    pp.trend.rejh0 <- pp.trend.teststat<df.trend@cval[2] 
    
    #KPS
    kpss.mu <- ur.kpss(xi,type="mu",lags="long")
    kpss.mu.teststat <- kpss.mu@teststat
    kpss.mu.rejh0 <- kpss.mu.teststat>kpss.mu@cval[2]
    
    kpss.tau <- ur.kpss(xi,type="tau",lags="long")
    kpss.tau.teststat <- kpss.tau@teststat
    kpss.tau.rejh0 <- kpss.tau.teststat>kpss.tau@cval[2]
    
    table.rejh0[i,] <- c(df.none.rejh0,df.drift.rejh0,df.trend.rejh0,pp.drift.rejh0,pp.trend.rejh0,kpss.mu.rejh0,kpss.tau.rejh0)
  }
  cat("Unit root tests results: Reports TRUE if H0 is rejected and FALSE otherwise.", "\n")
  cat("ADF and PP test -> H0: the series is nonstationary.", "\n")
  cat("KPSS test -> H0: the series is stationary.", "\n")
  cat("\n")
  return(table.rejh0)
}