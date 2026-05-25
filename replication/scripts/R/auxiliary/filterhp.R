library(dlm)

filterHP <- function(series,lambda=1600){
        # Function description: HP filter using DLM package.
        if(!"ts" %in% class(series)) stop("series is not a \"ts\" object.")
        
        # Set state priors
        level <- series[1]
        slope <- mean(diff(series),na.rm=TRUE)
        
        # Set up HP filter in a DLM model
        model <- function(param){
                trend <- dlmModPoly(dV = 1,
                                    dW = c(0,1/lambda),
                                    m0 = c(level,slope),
                                    C0 = 2 * diag(2))
                
                # AR(2) model
                cycle <- dlmModARMA(ar     = ARtransPars(c(0,0)),
                                    sigma2 = 1e-07)      
                
                hp_filter_dlm <- trend  + cycle
                
                return(hp_filter_dlm)
        }
        
        # MLE Estimation
        MLE       <- dlmMLE(series,c(0.5,0.4),model)
        # Estimated parameters
        EstParams <- model(MLE$par)
        # Smoothed series
        Smooth_Estimates <- dlmSmooth(series,EstParams)
        
        # Trend and Cycle
        trend <- Smooth_Estimates$s[,1]
        cycle <- series - trend
        
        # Plot the data ---
        par(mfrow = c(2,1),
            oma = c(1,3,0,0) + 0.1,
            mar = c(1.5,1,1,1) + 0.1)
        plot(series,las=1,col="black")
        lines(trend,col="blue")
        legend("topleft",legend=c("Observed","Trend"),border=FALSE,bty="n",col=c("black","blue"),lwd=1)
        title(main="HP Filter - Trend")
        par(mar = c(1,1,1.5,1) + 0.1)
        plot(cycle,las=1,col="red")
        title(main="HP Filter - Cycle")
        abline(h=0)
        par(mfrow = c(1,1),
            oma = c(0,0,0,0),
            mar = c(5.1,4.1,4.1,2.1))  
        
        # Return the data
        data <- ts.union(series,trend,cycle)
        return(data)
}