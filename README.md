# Crop Classification with ML

This project applies **Random Forest** classification to analyze and classify NDVI (Normalized Difference Vegetation Index) raster images specifically for crop types throughout the year.

## Folder Description

This project consists of several folders that contain the necessary data and scripts for the classification process:

- **0_NDVI_Rasters**: Contains NDVI raster images for each month from Sentinel 2. However, due to their large file sizes, these raster files cannot be shared in this GitHub repository.
- **1_Training_Samples**: Holds training and testing shapefiles with known crop classes.
- **2_Outputs**: Stores the output classified raster images and results.

## Key Steps

### 1. NDVI Rasters
- Load NDVI raster images for each month (January to December).

### 2. Data Preparation
- Stack the NDVI rasters into a multi-layered dataset.
- Use training data (sample points with known crop classes) and testing data (points for validation).

### 3. Training the Models
- Train a **Random Forest** model using the stacked NDVI data and training samples.
- Train an **XGBoost** model using the same data for comparison.
- Both models learn to classify different crop types based on the input NDVI values.

### 4. Reducing Sample Size
- Reduce the training data to 10% of the original size while maintaining representative samples from each class.

### 5. Model Evaluation
- Evaluate the model's performance by checking the **Out-of-Bag (OOB)** error for Random Forest and using cross-validation for XGBoost.
- Analyze the importance of different variables (monthly NDVI data) in crop classification for both models.

### 6. Image Classification
- Apply the trained Random Forest and XGBoost models to classify the entire NDVI raster stack.
- The results are classified images that map different crop types.

### 7. Accuracy Assessment
- Validate the classifications using testing data.
- Use **Confusion Matrices** to evaluate the performance of both models in predicting each crop class.

### 8. Output
- Save the final classified images as **GeoTIFF** files for further analysis.
  
---

In summary, this project uses satellite NDVI data and machine learning to map different crop types over time, producing a classified raster image of the area. This project was part of a practical exercise for the Advanced Image Analysis elective course at ITC, University of Twente.
