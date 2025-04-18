context("Machine Learning Density-Based Clustering")

# Test fixed model #############################################################
options <- initMlOptions("mlClusteringDensityBased")
options$addPredictions <- FALSE
options$predictionsColumn <- ""
options$validationMeasures <- TRUE
options$distance <- "normalDensities"
options[["kDistancePlot"]] <- TRUE
options$modelOptimization <- "manual"
options$tsneClusterPlot <- TRUE
options$predictors <- c("Alcohol", "Malic", "Ash", "Alcalinity", "Magnesium", "Phenols",
                           "Flavanoids", "Nonflavanoids", "Proanthocyanins", "Color",
                           "Hue", "Dilution", "Proline")
options$predictors.types <- rep("scale", length(options$predictors))
options$setSeed <- TRUE
options$tableClusterInformationBetweenSumOfSquares <- TRUE
options$tableClusterInformationSilhouetteScore <- TRUE
options$tableClusterInformationTotalSumOfSquares <- TRUE
options$clusterMeanPlot <- TRUE
options$clusterMeanPlotBarPlot <- TRUE
options$clusterMeanPlotSingleFigure <- TRUE
set.seed(1)
results <- jaspTools::runAnalysis("mlClusteringDensityBased", "wine.csv", options)


test_that("Evaluation Metrics table results match", {
	table <- results[["results"]][["clusterEvaluationMetrics"]][["data"]]
	jaspTools::expect_equal_tables(table,
		list("Maximum diameter", 11.1799587393255, "Minimum separation", 1.5585337772221,
			 "Pearson's <unicode><unicode>", 0.148453138441374, "Dunn index",
			 0.139404251264358, "Entropy", 1.06944886479123, "Calinski-Harabasz index",
			 9.2823961813625))
})

test_that("Cluster Information table results match", {
	table <- results[["results"]][["clusterInfoTable"]][["data"]]
	jaspTools::expect_equal_tables(table,
		list("Noisepoints", 0, 0, 85, 0, 1, 0.945752634943818, 0.221855962945892,
			 74, 570.509086532522, 2, 0.0134395257890548, 0.341893541680517,
			 5, 8.10716385876036, 3, 0.00960297029427597, 0.445300681167908,
			 5, 5.79282743516943, 4, 0.0312048689728515, 0.289663743234524,
			 9, 18.8238030065082))
})

test_that("All predictors plot matches", {
	plotName <- results[["results"]][["clusterMeans"]][["collection"]][["clusterMeans_oneFigure"]][["data"]]
	testPlot <- results[["state"]][["figures"]][[plotName]][["obj"]]
	jaspTools::expect_equal_plots(testPlot, "all-predictors")
})

test_that("Density-Based Clustering table results match", {
	table <- results[["results"]][["clusteringTable"]][["data"]]
	jaspTools::expect_equal_tables(table,
		list(-0.01, 707.23, 872.69, 4, 0.350534294802836, 178))
})

test_that("K-Distance Plot matches", {
	plotName <- results[["results"]][["kdistPlot"]][["data"]]
	testPlot <- results[["state"]][["figures"]][[plotName]][["obj"]]
	jaspTools::expect_equal_plots(testPlot, "k-distance-plot")
})

test_that("t-SNE Cluster Plot matches", {
	skip("Does not reproduce on windows <-> osx")
	plotName <- results[["results"]][["plot2dCluster"]][["data"]]
	testPlot <- results[["state"]][["figures"]][[plotName]][["obj"]]
	jaspTools::expect_equal_plots(testPlot, "t-sne-cluster-plot")
})
