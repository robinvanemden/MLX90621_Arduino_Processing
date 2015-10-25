
####
#
#  read_sensor_data.R
#
#  Import script. Parses MLX sensor data
#
#  Robin van Emden - robin@pavlov.io - 2015
#
####


## configuration

#  working directory
wdir <- "C:/Users/robin/Desktop/read_sensor_data"

#  sensor data file
sdf <- "2015_10_23_13_51_51_698_output.txt"

#  set working directory
setwd(wdir)

#  sensor data directory
sddir <- "sensor_data"

#  build path to sensor file
sdfpath <- paste0(sddir, "/", sdf)

#  dataframe cache directory
dfcdir <- "df_cache"
  
#  build path to cache file
dfpath <- paste0(dfcdir,"/",sdf,".Rda")



## check if conversion has been cached

if (!file.exists(dfpath)) {

  
## main script

#  load file and separate by ~
data <- read.table(sdfpath, sep = "~" , header = F)

#  delete date/time column
data$V2 <- NULL

#  remove [] characters
data$V3 <- substring(data$V3, 2, 96)
data$V4 <- substring(data$V4, 2, 96)
data$V5 <- substring(data$V5, 2, 96)
data$V6 <- substring(data$V6, 2, 96)

#  comma separate each column representing one row of IR temperature pixels
t1 <- data.frame(do.call('rbind', strsplit(data$V3,',',fixed=TRUE)))
t2 <- data.frame(do.call('rbind', strsplit(data$V4,',',fixed=TRUE)))
t3 <- data.frame(do.call('rbind', strsplit(data$V5,',',fixed=TRUE)))
t4 <- data.frame(do.call('rbind', strsplit(data$V6,',',fixed=TRUE)))

#  remove the original temperature columns
data$V3 <- NULL
data$V4 <- NULL
data$V5 <- NULL
data$V6 <- NULL

#  merge all created dataframes
data <- cbind(t1,t2,t3,t4,data)

#  remove temporary variables
rm(t1,t2,t3,t4)

#  assign variable names var1 ... var64
names(data)[1:64] <- paste("Var", 1:64, sep="")

#  convert to numeric
indx <- sapply(data, is.factor)
data[indx] <- lapply(data[indx], function(x) as.numeric(as.character(x)))


#  save to cache
save(data,file=dfpath)


## cache file does exist, load dataframe

} else { load(file=dfpath)  }


##############################################################


## Quick look at the data

#  calculate row temperature means
means <- rowMeans(data[,1:64])
means <- runmed(means,351)
plot(means,type="l", ylab="mean sensor temperatures", xlab="t" )
par(new=TRUE)
plot(data$V1, type="l", col="green", axes=FALSE, main=NULL, xlab = "" , ylab="" )


