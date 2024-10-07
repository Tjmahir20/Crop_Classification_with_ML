# If not installed, you need to install all relevant packages first
#install.packages("raster", "caret", "randomForest", "sp", "rgdal", "ggplot2")

#load libraries
library(raster)
library(randomForest)
library(sp)
library(rgdal)
library(ggplot2)
library(caret)
set.seed(123)

# Setting-up the working directory 

# setwd("D://Advanced Image Analysis Lab//05 Random Forest//0_NDVI_Rasters")
# setwd("./0_NDVI_Rasters")
# set.seed(123)

###### Import images
NDVI_January21  = "21_01_NDVIBand8ABand4.tif"
NDVI_February15  = "15_02_NDVIBand8ABand4.tif"
NDVI_March30  = "30_03_NDVIBand8ABand4.tif"
NDVI_April19  = "19_04_NDVIBand8ABand4.tif"
NDVI_May11  = "11_05_NDVIBand8ABand4.tif"
NDVI_June28  = "28_06_NDVIBand8ABand4.tif"
NDVI_July23  = "23_07_NDVIBand8ABand4.tif"
NDVI_August24  = "24_08_NDVIBand8ABand4.tif"
NDVI_September21  = "21_09_NDVIBand8ABand4.tif"
NDVI_October31  = "31_10_NDVIBand8ABand4.tif"
NDVI_November10  = "10_11_NDVIBand8ABand4.tif"
NDVI_December12  = "30_12_NDVIBand8ABand4.tif"

#### Stacking of Rasters
inraster        = stack(NDVI_January21, NDVI_February15,
                        NDVI_March30,NDVI_April19 ,
                        NDVI_May11,NDVI_June28, NDVI_July23,
                        NDVI_August24,NDVI_September21,NDVI_October31,
                        NDVI_November10,NDVI_December12)


# typeof(inraster)
inraster

getwd()


names(inraster) = c('NDVI_January21', 'NDVI_February15',
                    'NDVI_March30','NDVI_April19' ,
                    'NDVI_May11','NDVI_June28', 'NDVI_July23',
                    'NDVI_August24','NDVI_September21','NDVI_October31',
                    'NDVI_November10','NDVI_December12')


#==================================================================================
# Import training and validation data


#==================================================================================
# Setting-up the working directory 
setwd('..//1_Training_Samples')

trainingData  =  shapefile("trainingsamplesPnt_NL.shp")

TestingData = shapefile("testingsamplesPnts_NL.shp")

summary(trainingData)
Class_Distribution = as.data.frame(table(trainingData$Class))
Class_Distribution

barplot(prop.table(table(trainingData$Class)),
        col = rainbow(7),
        ylim = c(0, 0.6),
        main = "Class Distribution")

#==================================================================================
# Reducing the Number of Samples (Keeping 10% per class) 
#==================================================================================
target_percent <- c(1, 0.9, 0.7, 0.5)
target_percent <- 1

for (i in seq_len(length(target_percent))){
  print(i)
}

# Create an empty DataFrame to store reduced datasets
Reduced_DF <- data.frame(matrix(nrow=1,ncol=3))
Reduced_DF
names(Reduced_DF) <- c('Class','x','y')
Reduced_DF

class_value <- as.list (unique(trainingData$Class))
for (i in class_value) {
  print(i)
}

# Loop through unique class values
for (i in class_value) {
  
  # Subset the data for the current class
  class_subset <- trainingData[trainingData$Class == i, ]
  
  # Calculate the number of classes to keep
  s_c_train <- class_subset[sample(nrow(class_subset),as.integer(nrow(class_subset)*target_percent)),]
  s_c_train <- as.data.frame(s_c_train)
  s_c_train <- s_c_train[,c(1:3)]
  
  # names(s_c_train) <- c('Class','x','y')
  # Add the reduced dataset to the DataFrame
  Reduced_DF <- rbind(Reduced_DF,s_c_train)
}

Reduced_DF <- Reduced_DF[!is.na(Reduced_DF$Class),]
sp_reduced_df <- SpatialPointsDataFrame(Reduced_DF[,c(2,3)], data=as.data.frame(Reduced_DF[,1]))
names(sp_reduced_df) <- c("Class")
unique(sp_reduced_df$Class)

### Bar Plot Distribution of sp_reduced_df
barplot(prop.table(table(sp_reduced_df$Class)),
        col = rainbow(7),
        ylim = c(0, 0.6),
        main = "Resampled Class Distribution")

### Summary Table of Reduced Dataset
table(sp_reduced_df$Class)
table(trainingData$Class)

Class_Distribution = as.data.frame(table(sp_reduced_df$Class))
Class_Distribution

#==================================================================================
# Extract raster values for the training samples 
#==================================================================================
training_data  = extract(inraster, sp_reduced_df)
training_response = as.factor(sp_reduced_df$Class)
# sp_reduced_df$Class

#==================================================================================
#Select the number of input variables(i.e. predictors, features)
#==================================================================================
selection<-c(1:12) 
training_predictors = training_data[,selection] 

# selection<-c(3:10)

#==================================================================================
# Train the random forest
#==================================================================================

ntree = 1000    #number of trees to produce per iteration
mtry = 5       # number of variables used as input to split the variables
r_forest = randomForest(training_predictors, y=training_response, mtry=mtry, ntree = ntree, keep.forest=TRUE, importance = TRUE, proximity=TRUE) 

#===================================================================================
#Investigate the OOB (Out-Of-the bag) error
#===================================================================================
r_forest

#===================================================================================
# Assessment of variable importance
#===================================================================================
imp =importance(r_forest)  #for ALL classes individually
imp                        #display importance output in console
varImpPlot(r_forest)
varUsed(r_forest)
importance(r_forest)

#=======================================================================================
#Evaluate the impact of the mtry on the accuracy
#========================================================================================

mtry <- tuneRF(training_predictors,training_response, ntreeTry=ntree,
               stepFactor=1.5,improve=0.01, trace=TRUE, plot=TRUE)
best.m <- mtry[mtry[, 2] == min(mtry[, 2]), 1]
print(mtry)
print(best.m)

#======================================================================================
#Number of tree nodes
#======================================================================================
hist(treesize(r_forest), main= "Number of Nodes for the trees",
     col= "green")

getTree(r_forest, 1, labelVar = TRUE) # inspect the tree characteristics

#==========================================================================================
# Classify the entire image:define raster data to use for classification
#=========================================================================================
predictor_data = subset(inraster, selection)

setwd('..//2_Outputs')#change this to your output directory if different 

#==========================================================================================
# Classify the entire image
#=========================================================================================

predictions = predict(predictor_data, r_forest, format=".tif", overwrite=TRUE, progress="text", type="response") 

#==========================================================================================
# Assess the classification accuracy
#=========================================================================================

Testing=extract(predictions, TestingData) # extracts the value of the classified raster at the validation point locations


confusionMatrix(as.factor(Testing), as.factor(TestingData$ClassID) )

confusionMatrix(as.factor(Testing), as.factor(TestingData$ClassID) )$byClass[, 1]
confusionMatrix(as.factor(Testing), as.factor(TestingData$ClassID) )$byClass[]

# write to a new geotiff file
path <- '..//2_Outputs'
rf <- writeRaster(predictions, filename=file.path(path, "classification results.tif"), format="GTiff", overwrite=TRUE)



