# If not installed, you need to install all relevant packages first
#install.packages("raster", "xgboost", "caret", "sp", "rgdal", "ggplot2")
install.packages("xgboost")
install.packages("rBayesianOptimization")



#load libraries
library(raster)
library(sp)
library(rgdal)
library (caret)
library(xgboost)
library(rBayesianOptimization)
set.seed(123)


# Setting-up the working directory 
# setwd("D://Advanced Image Analysis Lab//05 Random Forest//NDVI_IMAGES_zipped")
setwd("./0_NDVI_Rasters")

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

inraster        = stack(NDVI_January21, NDVI_February15,
                        NDVI_March30,NDVI_April19 ,
                        NDVI_May11,NDVI_June28, NDVI_July23,
                        NDVI_August24,NDVI_September21,NDVI_October31,
                        NDVI_November10,NDVI_December12)


inraster

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
trainingData$Class = as.factor(trainingData$Class)
summary(trainingData)

barplot(prop.table(table(trainingData$Class)),
        col = rainbow(7),
        ylim = c(0, 0.7),
        main = "Class Distribution")

TestingData = shapefile("testingsamplesPnts_NL.shp")
TestingData$Class = as.factor(TestingData$Class)
summary(TestingData)

barplot(prop.table(table(TestingData$Class)),
        col = rainbow(7),
        ylim = c(0, 0.7),
        main = "Class Distribution")

#==================================================================================
# Reducing the Number of Samples (Keeping 10% per class) 
#==================================================================================
target_percent <- c(1, 0.9, 0.6, 0.3, 0.2)
target_percent <- 1

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


### Summary Table of Reduced Dataset
table(sp_reduced_df$Class)
table(trainingData$Class)


#==================================================================================
# Extract raster values for the training samples 
#==================================================================================
training_data  = extract(inraster, sp_reduced_df)
training_data

#table(data_balanced_over$cls)

#==================================================================================
# transforming dataframe into a matrix
#==================================================================================
train <- data.matrix(training_data)
#==================================================================================
# classes ID starts with 0 (instead of 1)
#==================================================================================
training_response = as.numeric (as.factor(sp_reduced_df$Class))-1
training_response

training_response = as.numeric(as.factor(sp_reduced_df$Class))-1
training_response


#==================================================================================
# Training the xgboost model
#==================================================================================

xgb_model <- xgboost(data = train, 
                   label = training_response,
                   booster = "gbtree",
                   eta = 0.1,
                   gamma = 10,
                   max_depth = 6, 
                   min_child_weight = 1,
                   nround=100, 
                   objective = "multi:softmax",
                   num_class = length(unique(training_response)),
              )
    
    
# summary(xgb_model)
# mat <- xgb.importance (feature_names = colnames(train),model = xgb_model)
# xgb.plot.importance (importance_matrix = mat[1:23]) 
    
# mat
# as.data.frame(table(mat))


#==========================================================================================
# Classify the entire image:define raster data to use for classification
#=========================================================================================

#change this to your output directory if different 
setwd('..//2_Outputs')


#==========================================================================================
# Classify the entire image
#=========================================================================================

result   <- predict(xgb_model, inraster [1:(nrow(inraster )*ncol(inraster ))])
res      <- raster(inraster)
res      <- setValues(res,result+1)
res

#==========================================================================================
# Assess the classification accuracy
#=========================================================================================

Testing=extract(res, TestingData) # extracts the value of the classified raster at the validation point locations
confusionMatrix(as.factor(Testing), as.factor(TestingData$ClassID) )

confusionMatrix(as.factor(Testing), as.factor(TestingData$ClassID) )$byClass[, 1]

confusionMatrix(as.factor(Testing), as.factor(TestingData$ClassID) )$byClass[]
#==========================================================================================
# Save the classification results
#=========================================================================================

Class_Results = writeRaster(res, 'classification_results_XGBoost.tif', overwrite=TRUE)

