############################################################
# BUS 462 | Spring 2022
# Group Project 
# Team E.Gamma
# I pledge on my honor that I have neither received nor given unauthorized assistance on this deliverable.
############################################################


#### PREAMBLE : ## Clearing buffers ####
cat("\014")  # Clear Console
rm(list = ls(all.names = TRUE))# clear all
gc()

# libraries
library(data.table)
library(stargazer)
library(ggplot2)
library(PerformanceAnalytics)
library(dplyr)
library(pastecs)
library(pscl)
library(corrplot)
library(tidyr)
library(chron)
library(rpart)
library(rpart.plot)
library(MASS)

############################################################

# 1) Data Cleaning 

#Loading the files
atj_2019 <- read.csv("C:/Users/kashi/Desktop/BUS 462/Assignments/Group project/Files/atj_2019.csv")
atj_2020 <- read.csv("C:/Users/kashi/Desktop/BUS 462/Assignments/Group project/Files/atj_2020.csv")
taxi_zones <- read.csv("C:/Users/kashi/Desktop/BUS 462/Assignments/Group project/Files/taxi+_zone_lookup.csv")


# Merge the location file to associate pick up and drop off locations with names over numbers.
# This will help in the interpretation of results.
merged2019 <- merge(atj_2019,taxi_zones,by.x = c("PULocationID"),by.y = c("LocationID"))
names(merged2019)[names(merged2019) == 'Zone'] <- 'PUZone'
names(merged2019)[names(merged2019) == 'Borough'] <- 'PUBorough'
names(merged2019)[names(merged2019) == 'service_zone'] <- 'PUservice_zone'
merged2019 <- merge(merged2019,taxi_zones,by.x = c("DOLocationID"),by.y = c("LocationID"))
names(merged2019)[names(merged2019) == 'Zone'] <- 'DOZone'
names(merged2019)[names(merged2019) == 'Borough'] <- 'DOBorough'
names(merged2019)[names(merged2019) == 'service_zone'] <- 'DOservice_zone'
colnames(merged2019)

# [1] "DOLocationID"          "PULocationID"          "VendorID"              "tpep_pickup_datetime" 
# [5] "tpep_dropoff_datetime" "passenger_count"       "trip_distance"         "RatecodeID"           
# [9] "payment_type"          "fare_amount"           "extra"                 "tip_amount"           
# [13] "tolls_amount"          "total_amount"          "PUBorough"             "PUZone"               
#[17] "PUservice_zone"        "DOBorough"             "DOZone"                "DOservice_zone"       
# [21] "tipdivtotal"           "trip_time"             "numeric_trip_time"     "binary" 


merged2020 <- merge(atj_2020,taxi_zones,by.x = c("PULocationID"),by.y = c("LocationID"))
names(merged2020)[names(merged2020) == 'Zone'] <- 'PUZone'
names(merged2020)[names(merged2020) == 'Borough'] <- 'PUBorough'
names(merged2020)[names(merged2020) == 'service_zone'] <- 'PUservice_zone'
merged2020 <- merge(merged2020,taxi_zones,by.x = c("DOLocationID"),by.y = c("LocationID"))
names(merged2020)[names(merged2020) == 'Zone'] <- 'DOZone'
names(merged2020)[names(merged2020) == 'Borough'] <- 'DOBorough'
names(merged2020)[names(merged2020) == 'service_zone'] <- 'DOservice_zone'
colnames(merged2020)

# Checking if any columns have NA Values
names(merged2019)[sapply(merged2019, anyNA)] # "PUZone" "DOZone"
names(merged2020)[sapply(merged2020, anyNA)] # "PUZone" "DOZone"
# As mentioned earlier, the zone information (that were merged later on) are not of use in the analysis,
# but will come handy in the interpretation. Therefore, these data points will not need to be replaced or omitted.
# NAs are associated with Pick up and Drop Off locations 264 and 265. 

#ggplot(merged2019, aes(x=tip_amount,y=total_amount)) + geom_point() + geom_smooth(method=lm, se=FALSE, col='blue', size=1) + ggtitle("Tip/Total 2019 Data Points")
#ggplot(merged2020, aes(x=tip_amount,y=total_amount)) + geom_point() + geom_smooth(method=lm, se=FALSE, col='red', size=1) + ggtitle("Tip/Total 2020 Data Points")

# Add a column which calculates the tip per trip as a fraction of the total fare
merged2019$tipdivtotal <- merged2019$tip_amount/merged2019$total_amount
merged2020$tipdivtotal <- merged2020$tip_amount/merged2020$total_amount
head(merged2019)
head(merged2020)

#plot(merged2019$tip_amount, merged2019$tipdivtotal)
#plot(merged2020$tip_amount, merged2020$tipdivtotal)

# Get rid of rows in the dataframe that have a negative tipdivtotal (You cannot have a negative tip)
min(merged2019$tipdivtotal, na.rm = TRUE) # -0.334002
dim(merged2019) # 1453902       
merged2019 <- subset(merged2019,tipdivtotal >= 0)
min(merged2019$tipdivtotal) # 0 
dim(merged2019) # 1453706       

min(merged2020$tipdivtotal, na.rm=TRUE) # -49.44776
dim(merged2020) # 629492 
merged2020 <- subset(merged2020,tipdivtotal >= 0)
min(merged2019$tipdivtotal) # 0 
dim(merged2020) # 629128 

# Get rid of rows in the dataframe that have negative tip_amount
min(merged2019$tip_amount) # -88.88
dim(merged2019)
merged2019 <- subset(merged2019, tip_amount >= 0)
min(merged2019$tip_amount) # 0 
dim(merged2019)

min(merged2020$tip_amount) # -36.3
dim(merged2020)
merged2020 <- subset(merged2020, tip_amount >= 0)
min(merged2020$tip_amount) # 0 
dim(merged2020)


#ggplot(merged2019, aes(x=tip_amount,y=tipdivtotal)) + geom_point() + geom_smooth(method=lm, se=FALSE, col='blue', size=1) + ggtitle("Tip/Total 2019 Data Points")
#ggplot(merged2020 , aes(x=tip_amount,y=tipdivtotal)) + geom_point() + geom_smooth(method=lm, se=FALSE, col='red', size=1) + ggtitle("Tip/Total 2020 Data Points")

# Look at the tip_amount table and observe anomalies
summary(merged2019$tip_amount)
# Min. 1st Qu.  Median    Mean    3rd Qu.    Max. 
# 0.000   1.700   2.360   3.087   3.460 333.330 
summary(merged2020$tip_amount)
# Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 0.000   1.460   2.160   2.583   3.060 442.180 

# Looking at the maximum tip amounts, these could be heavily skewing the data. 
# Eliminate all rows with tips more than $50 
merged2019 <- subset(merged2019, tip_amount <= 50)
merged2020 <- subset(merged2020, tip_amount <= 50)


#ggplot(merged2019, aes(x=tip_amount,y=tipdivtotal)) + geom_point() + geom_smooth(method=lm, se=FALSE, col='blue', size=1) + ggtitle("Tip/Total 2019 Data Points")
#ggplot(merged2020 , aes(x=tip_amount,y=tipdivtotal)) + geom_point() + geom_smooth(method=lm, se=FALSE, col='red', size=1) + ggtitle("Tip/Total 2020 Data Points")

# Check if tipdivtotal and tip_amount are normally distributed 
#hist(merged2019$tipdivtotal)
#hist(merged2020$tipdivtotal)


# The dates are currently incharacters format + AM/PM. In order to be able to perform an analysis on
# them, they need to be changed to POSIXct + military timing
merged2019$tpep_pickup_datetime = as.POSIXct(merged2019$tpep_pickup_datetime, format = "%Y-%m-%d %H:%M:%S")
str(merged2019$tpep_pickup_datetime) # POSIXct
merged2019$tpep_dropoff_datetime = as.POSIXct(merged2019$tpep_dropoff_datetime, format = "%Y-%m-%d %H:%M:%S")
str(merged2019$tpep_dropoff_datetime) # POSIXct

merged2020$tpep_pickup_datetime = as.POSIXct(merged2020$tpep_pickup_datetime, format = "%Y-%m-%d %H:%M:%S")
str(merged2020$tpep_pickup_datetime) # POSIXct
merged2020$tpep_dropoff_datetime = as.POSIXct(merged2020$tpep_dropoff_datetime, format = "%Y-%m-%d %H:%M:%S")
str(merged2020$tpep_dropoff_datetime) # POSIXct

# Add a column that calculates the trip time (DOtime - PUtime)
merged2019$trip_time <- merged2019$tpep_dropoff_datetime - merged2019$tpep_pickup_datetime
head(merged2019$trip_time)
merged2020$trip_time <- merged2020$tpep_dropoff_datetime - merged2020$tpep_pickup_datetime
head(merged2020$trip_time)
str(merged2019$trip_time)

# Create a new column that holds the trip_time data as a numeric value, instead of a difftime value
merged2019$numeric_trip_time <- as.numeric(merged2019$trip_time)
str(merged2019$trip_time) # difftime
str(merged2019$numeric_trip_time) # num 
merged2020$numeric_trip_time <- as.numeric(merged2020$trip_time)
str(merged2020$numeric_trip_time) # num

# Get rid of rows in the dataframe that have a negative trip_time (You cannot have a negative travel time)
dim(merged2019) # 1453469       
min(merged2019$numeric_trip_time) # -256763
merged2019 <- subset(merged2019, numeric_trip_time >= 0)
min(merged2019$numeric_trip_time) # 0 
dim(merged2019) # 1453468       

dim(merged2020) # 628927     
min(merged2020$numeric_trip_time) # -31873874
merged2020 <- subset(merged2020, numeric_trip_time >= 0)
min(merged2019$numeric_trip_time) # 0 
dim(merged2020) # 628926      

# Add a binary column that classifies the tip/totalamount as a binary variable based on the median tip amount
merged2019$binary <- ifelse(merged2019$tipdivtotal>median(merged2019$tipdivtotal,na.rm = TRUE),1,0)
merged2020$binary <- ifelse(merged2020$tipdivtotal>median(merged2020$tipdivtotal, na.rm = TRUE),1,0)
median(merged2020$tipdivtotal) # 0.1663405

# Add a dummy variable that classifies thepickup time by the time of the day where if the pickup time is 
# between 00:00:00 and 05:00:00 = 1 Early Morning
# between 05:00:01 and 09:00:00 = 2 Morning Rush Hour
# between 09:00:01 and 16:00:00 = 3 Working Hours 
# between 16:00:01 and 20:00:00 = 4 Evening Rush Hour
# between 20:00:01 and 23:59:59 = 5 Night 
merged2019$PUdate <- as.Date(merged2019$tpep_pickup_datetime)
class(merged2019$PUdate)
merged2019$PUtime <- format(merged2019$tpep_pickup_datetime,format = "%H:%M:%S")
merged2019$PUtime <- as.times(merged2019$PUtime)
class(merged2019$PUtime)
breaks <- c('00:00:00', '05:00:00', '09:00:00', '16:00:00','20:00:00', '23:59:59')
labels <- c(1,2,3,4,5)
h1 <- chron(times=merged2019$PUtime)
br <- chron(times=breaks)
merged2019$time_of_day <-  cut(h1, br, labels=labels)
str(merged2019$time_of_day) # Factor
merged2019$time_of_day <- as.numeric(merged2019$time_of_day)
head(merged2019)

merged2020$PUdate <- as.Date(merged2020$tpep_pickup_datetime)
class(merged2020$PUdate)
merged2020$PUtime <- format(merged2020$tpep_pickup_datetime,format = "%H:%M:%S")
merged2020$PUtime <- as.times(merged2020$PUtime)
class(merged2020$PUtime)
breaks <- c('00:00:00', '05:00:00', '09:00:00', '16:00:00','20:00:00', '23:59:59')
labels <- c(1,2,3,4,5)
h2 <- chron(times=merged2020$PUtime)
br <- chron(times=breaks)
merged2020$time_of_day <-  cut(h2, br, labels=labels)
str(merged2020$time_of_day) # Factor
merged2020$time_of_day <- as.numeric(merged2020$time_of_day)
head(merged2020)

# Classify the days of the week using categorical/dummy variables therefore, to assign every date with a weekday.
# Weekdays are classified between 1-7 as shown below:
# Sunday = 1
# Monday = 2
# Saturday = 7
merged2019$dow <- as.POSIXlt(merged2019$PUdate)$wday + 1
str(merged2019$dow)
head(merged2019)
merged2020$dow <- as.POSIXlt(merged2020$PUdate)$wday + 1
str(merged2020$dow)
head(merged2020)

# Final check 
names(merged2019) # check titles for each of the column
head(merged2019,5) # check the first five rows for each column
str(merged2019) # check for the data types of each column (integer, num)
class(merged2019) # check for the data class of the dataframe
summary(merged2019) # perform quick overview of data
dim(merged2019) # check for the number of columns by rows

names(merged2020)
head(merged2020,5)
str(merged2020)
class(merged2020)
summary(merged2020)
dim(merged2020)

# 2) Summary Analytics

# Summary statistics for the merged2019 dataset
summary(merged2019)

# Summary statistics for the merged2020 dataset
summary(merged2020)

# Correlation Matrix visualizations
corrMatrix2019 <- cor(select_if(merged2019,is.numeric), use="complete.obs")
#corrplot(corrMatrix2019, method="color",tl.col="black",tl.cex = 0.5, col=colorRampPalette(c("black","white","gold"))(100))
corrMatrix2020 <- cor(select_if(merged2020,is.numeric), use="complete.obs")
#corrplot(corrMatrix2020,method="color",tl.col="black",tl.cex = 0.5, col=colorRampPalette(c("black","white","gold"))(100))

# Create an interaction variable between total_amount and trip_time
merged2019$totamt_x_tripdist <- merged2019$total_amount * merged2019$trip_distance
merged2020$totamt_x_tripdist <- merged2020$total_amount * merged2020$trip_distance

# Dividing the datasets based on high and low tip amounts
lowtips_2019 <- subset(merged2019, binary==0)
hightips_2019 <- subset(merged2019, binary==1)

# Summary analysis for 2019 dataset, for tips lower than the median
summary(lowtips_2019)

# Summary analysis for 2019 dataset, for tips higher than the median
summary(hightips_2019)

# Dividing the datasets based on high and low tip amounts
lowtips_2020 <- subset(merged2020, binary==0)
hightips_2020 <- subset(merged2020, binary==1)

# Summary analysis for 2019 dataset, for tips lower than the median
summary(lowtips_2020)

# Summary analysis for 2019 dataset, for tips higher than the median
summary(hightips_2020)

# Correlation Matrix 2019
cor(merged2019[, unlist(lapply(merged2019, is.numeric))], use="complete.obs") 

# Correlation Matrix 2020
cor(merged2020[, unlist(lapply(merged2020, is.numeric))], use="complete.obs") 

# Histograms for 2019 Data
#par(mfrow=c(2,2))
#hist(hightips_2019$trip_distance, main = "Trip Distance for High Tip 2019 Trips", col = "darkmagenta", freq = FALSE, xlim=c(0,50), xlab = "Trip Distance in Miles")
#hist(lowtips_2019$trip_distance, main = "Trip Distance for Low Tip 2019 Trips", col = "aquamarine", freq = FALSE, xlab = "Trip Distance in Miles")
#hist(hightips_2019$passenger_count, main = "Passenger Count for High Tip 2019 Trips", freq = FALSE, col = "burlywood4", xlab = "Passenger Counts")
#hist(lowtips_2019$passenger_count, main = "Passenger Count for Low Tip 2019 Trips", freq = FALSE, col = "coral2", xlab = "Passenger Counts")
#hist(hightips_2019$VendorID, main = "VendorID for High Tip 2019 Trips", freq = FALSE, col = "blueviolet", xlab = "VendorID")
#hist(lowtips_2019$VendorID, main = "VendorID for Low Tip 2019 Trips", freq = FALSE, col = "lightblue1", xlab = "VendorID")
#hist(hightips_2019$fare_amount, main = "Fare Amount for High Tip 2019 Trips", freq = FALSE, col =  "mediumorchid1", xlab =  "Fare Amount in $")
#hist(lowtips_2019$fare_amount, main = "Fare Amount for Low Tip 2019 Trips", freq = FALSE, col =  "navajowhite", xlab =  "Fare Amount in $")
#hist(hightips_2019$tipdivtotal, main = "Tip/Total for High 2019 Trips", freq = FALSE, col = "palevioletred1", xlab = "Fraction", xlim=c(0,0.4))
#hist(lowtips_2019$tipdivtotal, main = "Tip/Total for Low 2019 Trips", freq = FALSE, col = "seagreen2", xlab = "Fraction", xlim=c(0,0.2))
#hist(hightips_2019$numeric_trip_time, main ="Trip Time in Seconds for High 2019 Trips", freq = FALSE, col = "tan3", xlab = "Time in Seconds", xlim = c(0,10000))
#hist(lowtips_2019$numeric_trip_time, main ="Trip Time in Seconds for Low 2019 Trips", freq = FALSE, col = "yellow", xlab = "Time in Seconds", xlim = c(0,10000))

# Histograms for 2020 Data
#hist(hightips_2020$trip_distance, main = "Trip Distance for High Tip 2020 Trips", col = "darkmagenta", freq = FALSE, xlim=c(0,50), xlab = "Trip Distance in Miles")
#hist(lowtips_2020$trip_distance, main = "Trip Distance for Low Tip 2020 Trips", col = "aquamarine", freq = FALSE, xlim=c(0,50), xlab = "Trip Distance in Miles")
#hist(hightips_2020$passenger_count, main = "Passenger Count for High Tip 2020 Trips", freq = FALSE, col = "burlywood4", xlab = "Passenger Counts")
#hist(lowtips_2020$passenger_count, main = "Passenger Count for Low Tip 2020 Trips", freq = FALSE, col = "coral2", xlab = "Passenger Counts")
#hist(hightips_2020$VendorID, main = "VendorID for High Tip 2020 Trips", freq = FALSE, col = "blueviolet", xlab = "VendorID")
#hist(lowtips_2020$VendorID, main = "VendorID for Low Tip 2020 Trips", freq = FALSE, col = "lightblue1", xlab = "VendorID")
#hist(hightips_2020$fare_amount, main = "Fare Amount for High Tip 2020 Trips", freq = FALSE, col =  "mediumorchid1", xlab =  "Fare Amount in $")
#hist(lowtips_2020$fare_amount, main = "Fare Amount for Low Tip 2020 Trips", freq = FALSE, col =  "navajowhite", xlab =  "Fare Amount in $")
#hist(hightips_2020$tipdivtotal, main = "Tip/Total for High 2020 Trips", freq = FALSE, col = "palevioletred1", xlab = "Fraction", xlim=c(0,0.4))
#hist(lowtips_2020$tipdivtotal, main = "Tip/Total for Low 2020 Trips", freq = FALSE, col = "seagreen2", xlab = "Fraction", xlim=c(0,0.4))
#hist(hightips_2020$numeric_trip_time, main ="Trip Time in Seconds for High 2020 Trips", freq = FALSE, col = "tan3", xlab = "Time in Seconds", xlim = c(0,10000))
#hist(lowtips_2020$numeric_trip_time, main ="Trip Time in Seconds for Low 2020 Trips", freq = FALSE, col = "yellow", xlab = "Time in Seconds", xlim = c(0,10000))

head(hightips_2019)
par(mfrow=c(1,1))


############################################################


# 2) Question 1 - OLS - # What variables impact tipping behavior

# AIC of using tip_amount as DV - justify why (AIC score when compared to AIC of using tip_amount of DV, controls for outliers and extremes)

#hist(merged2019$trip_distance, xlim = c(0,200))
summary(merged2019$trip_distance, merged2019$total_amount)
#plot(merged2019$trip_distance, merged2019$total_amount)
model1 <- lm(tipdivtotal ~ DOLocationID + VendorID + passenger_count + trip_distance + RatecodeID + total_amount + numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = merged2019)
summary(model1)
model2 <- lm(tipdivtotal ~ VendorID + passenger_count + trip_distance + total_amount + numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = merged2019)
summary(model2)
model3 <- lm(tipdivtotal ~ VendorID + passenger_count + trip_distance + total_amount + time_of_day + dow + totamt_x_tripdist, data = merged2019)
summary(model3)
model4 <- lm(tipdivtotal ~ VendorID + passenger_count + trip_distance + total_amount + totamt_x_tripdist, data = merged2019)
AIC(model1)
AIC(model2)
AIC(model3)
AIC(model4)


stargazer(model1, model2, model3, model4, type = "text")

# Looking at AIC scores and the adjusted R2, model ?? is the best way to go.  


############################################################


# 3) Question 2 - 

# As one might expect, logistic regression makes ample use of the logistic function as it outputs values 
# between 0 and 1 which we can use to model and predict responses.

merged2019$binary.factor <- factor(merged2019$binary)
m2019 <- sort(sample(nrow(merged2019), nrow(merged2019)*0.8))
train2019 <- merged2019[m2019,]
test2019 <- merged2019[-m2019,]
dim(train2019) # 1162774      30
dim(test2019) # 290694       30

train2019$time_of_day <- as.factor(train2019$time_of_day)
train2019$dow <- as.factor(train2019$dow)
train2019$VendorID <- as.factor(train2019$VendorID)
logitM <- glm(tipdivtotal ~ VendorID + passenger_count + trip_distance + total_amount + numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = train2019, family = "binomial")
summary(logitM)

# The results of this logit regression show that a certain vendorID(1) has a correlation with higher tips. 
# It also shows that time_of_day5 has a significant impact on tip variability (whether it is high or low). 
# Beyond these, the remaining variables are known to have an impact (even from OLS) with the exception of 
# passenger_count which is a control. 

# With our fitted model, we are interested in seeing how it would perform against our testing dataset. We can do 
# so by building a confusion matrix to display the success rate of the model's predictions on the testing dataset. 
# The predict function performs a prediction on a trip's tip based on the variables within the testing dataset 
# (total distance, trip time, tip amount, etc). The output of this function will provide us with probabilities. 
# The next command creates a vector of the 'Low' (low category, denoted as 0 in the dataset) with respect to the number
# of observations in the training data set. This is then converted into 'High' if the predicted probability is greater than half. 

# The table function builds the confusion matrix. 

test2019$time_of_day <- as.factor(test2019$time_of_day)
test2019$dow <- as.factor(test2019$dow)
test2019$VendorID <- as.factor(test2019$VendorID)

tips.prob = predict(logitM, test2019, type="response") # Predict on the test2019 test using the logitM model
tips.pred = rep("0",dim(train2019)[1]) # Place a "0" (low) on all of the rows in the tips.pred
tips.pred[tips.prob>.5] = "1" # if the predicted probability is greater than 0.5, then label it as "1" (high)
cm <- table(tips.pred,train2019$binary.factor)
cm

# tips.pred      0      1
#         0 581952 580782
#        1     23     17
# Where there is a match between 0,0 and 1,1, these are known as true positives and true positives, hence, 
# correctly predicted. 


# Calculate precision, accuracy, and recall 

# Recall is not so important, here, because we are interested in both, the ones it labelled as positive and the ones 
# it labelled as negative. Recall would have been of better interest if we were only interested in collecting
# all the "positive" samples. 

# Assume that the model predicting a low tip when the tip is actually low is TP = 578505
# Assume that the model predicting a high tip when the tip is actually high is TN = 5
# Assume that the model predicting a high tip when the tip is actually low is FP = 3
# Assume that the model predicting a low tip when the tip is actually high is FN = 581427

# Calculate manually since computer is unable to get 'caret' package
cm[1] # 581952
cm[2] # 23
cm[3] # 580782
cm[4] # 17


accuracyLOGIT <- sum(cm[1], cm[4]) / sum(cm[1:4]) 
accuracyLOGIT #  0.5005005
# The accuracy rate is 50.5%, really, close to 50% which means that it is as efficient or slightly less than random guessing. 
# This could imply that the model being used is not a very strong one. How many did it correctly predict as true?

precisionLOGIT <- cm[4] / sum(cm[4], cm[2])
precisionLOGIT # 0.425
# precision refers to how precise/accurate the model is when it comes to predicting positively, so basically, out of the 8 high tips
# that the model predicted, 5 were correct. Out of those predicted high, how many of them were actually high tips. 

sensitivityLOGIT <- cm[4] / sum(cm[4], cm[3])
sensitivityLOGIT # 2.927002e-05
# Sensitivity or recall measures how well the model predicted the positives that it predicted properly in comparison to the ones that 
# were actually high tips. Here, the model has performed terribly, almost missing every high tip and predicting it as low. The model
# is very good at predicting low tips, but that is because it predicts pretty much everything as low tips. 

fscoreLOGIT <- (2 * (sensitivityLOGIT * precisionLOGIT))/(sensitivityLOGIT + precisionLOGIT)
fscoreLOGIT # 5.853601e-05
# The F1 score indicates that the model does not do too well. The closer to 1 the score, the better. It measures for accuracy/
# reliability 

# Trying to refine our model using R's stepwise regression model (given that the results from LOGIT were not too pleasing)


head(train2019)
KSmodel <- glm(binary.factor ~ DOLocationID + VendorID + passenger_count + trip_distance + total_amount + 
                 numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = train2019, family = "binomial")
BModel <- stepAIC(KSmodel)   

# Result suggests to use all the variables we fed the model apart from DOLocationID (it eliminates and adds back variables one by one 
# to find the model with the lowest AIC). The model suggested by stepwise regression is precisely the model we used before
# in order to train our data and then tested on it. This gives an affirmation that the model we are using is fairly good, given the data
# we have, even though the predictions were not very accurate. 

#                     Df Deviance   AIC
#<none>                  1324158 1324194
#- passenger_count    1  1324177 1324211
#- dow                6  1324313 1324337
#- totamt_x_tripdist  1  1324428 1324462
#- numeric_trip_time  1  1324982 1325016
#- time_of_day        4  1325135 1325163
#- trip_distance      1  1341477 1341511
#- total_amount       1  1344963 1344997
#- VendorID           2  1579122 1579154


############################################################

warnings()

# 3) CART

install.packages("rpart")
install.packages("rpart.plot")


# Use the data created above for trained 2019 data to test on 2019 test data using CART

train2019 <- merged2019[m2019,]
test2019 <- merged2019[-m2019,]
prop.table(table(train2019$binary)) # Represent the column figures as percentages of the total 
prop.table(table(test2019$binary)) 

# CART prediction by inputting the variables 
train2019$time_of_day <- as.integer(train2019$time_of_day)
train2019$dow <- as.integer(train2019$dow)
train2019$VendorID <- as.integer(train2019$VendorID)
test2019$time_of_day <- as.integer(test2019$time_of_day)
test2019$dow <- as.integer(test2019$dow)
test2019$VendorID <- as.integer(test2019$VendorID)
CART1 <- rpart(binary ~ VendorID + passenger_count + trip_distance + total_amount + 
                 numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = train2019, method = 'class') 
C1 <- rpart.plot(CART1, fallen.leaves = TRUE, extra = 106) # tree plotting
C1 # Only divides the model from VendorID 
predict_CART1 <-predict(CART1, test2019, type = 'class')
confmatrixCART1 <- table(test2019$binary, predict_CART1)
confmatrixCART1 
CART1_accuracy <- sum(diag(confmatrixCART1)) / sum(confmatrixCART1)
CART1_accuracy # 0.7254168
CART1_precision <- confmatrixCART1[4]/sum(confmatrixCART1[4],confmatrixCART1[2])
CART1_precision # 0.8499493
CART1_sensitivity <- confmatrixCART1 [4] / sum(confmatrixCART1 [4], confmatrixCART1[3])
CART1_sensitivity # 0.6803415
CART1_fscore <- (2 * (CART1_sensitivity * CART1_precision))/(CART1_sensitivity + CART1_precision)
CART1_fscore # 0.7557463

calculateMAE

# THIS IS AN AMAZING MODEL WHEN APPLIED TO CART 


# Use the 2019 trained data, and apply it to the 2020 data to assess for the impacts of COVID
# CART1 <- rpart(binary ~ VendorID + passenger_count + trip_distance + total_amount + 
#  numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = train2019, method = 'class') 
# C1 <- rpart.plot(CART1, fallen.leaves = TRUE, extra = 106) # tree plotting
# C1 # Only divides the model from VendorID 
predict_CART2 <-predict(CART1, merged2020, type = 'class')
confmatrixCART2 <- table(merged2020$binary, predict_CART2)
confmatrixCART2
CART2_accuracy <- sum(diag(confmatrixCART2)) / sum(confmatrixCART2)
CART2_accuracy # 0.6756459
CART2_precision <- confmatrixCART2[4]/sum(confmatrixCART2[4],confmatrixCART2[2])
CART2_precision # 0.7390731
CART2_sensitivity <- confmatrixCART2[4] / sum(confmatrixCART2 [4], confmatrixCART2[3])
CART2_sensitivity # 0.6577974
CART2_fscore <- (2 * (CART2_sensitivity * CART2_precision))/(CART2_sensitivity + CART2_precision)
CART2_fscore # 0.6960708

# The 2019 CART model can predict on the 2020 model with 67.5% accuracy

# 2020 model on 2020 model to see the way in which their data splits
m2020 <- sort(sample(nrow(merged2020), nrow(merged2020)*0.8))
train2020 <- merged2020[m2020,]
test2020 <- merged2020[-m2020,]
prop.table(table(train2020$binary)) # Represent the column figures as percentages of the total 
prop.table(table(test2020$binary)) 
CART3 <- rpart(binary ~ VendorID + passenger_count + trip_distance + total_amount + 
                 numeric_trip_time + time_of_day + dow + totamt_x_tripdist, data = train2020, method = 'class') 
C3 <- rpart.plot(CART3, fallen.leaves = TRUE, extra = 106) # tree plotting
C3 # Only divides the model from VendorID - same for 2020 as for 2019! 


# Compare models using ROC curves and AUC score
# calculateMAE
# Analyse the way in which the trees divide and what the figures at the bottom of the trees mean

# HOW TO CHECK FOR NORMALITY
# SUMMARY STATS, SUMMARY GRAPHS
# BASIC AND GRAPHICAL ANALYSIS 