#
# Copyright (C) 2013-2021 University of Amsterdam
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

mlPrediction <- function(jaspResults, dataset, options, ...) {

  # Preparatory work
  model <- .mlPredictionReadModel(options)
  dataset <- .mlPredictionReadData(dataset, options, model)

  # Check if analysis is ready
  ready <- .mlPredictionReady(model, dataset, options)

  # Create a table summarizing the loaded model
  .mlPredictionModelSummaryTable(model, dataset, options, jaspResults, ready, position = 1)

  # Create a table containing the predicted values and predictors
  .mlPredictionsTable(model, dataset, options, jaspResults, ready, position = 2)

  # Add predicted outcomes to data set
  .mlPredictionsAddPredictions(model, dataset, options, jaspResults, ready)

  # Create the shap table
  .mlTableShap(dataset, options, jaspResults, ready, position = 3, purpose = "prediction", model)
}

is.jaspMachineLearning <- function(x) {
  inherits(x, "jaspMachineLearning")
}

# S3 method to identify the model type
.mlPredictionGetModelType <- function(model) {
  UseMethod(".mlPredictionGetModelType", model)
}
.mlPredictionGetModelType.kknn <- function(model) {
  gettext("K-nearest neighbors")
}
.mlPredictionGetModelType.lda <- function(model) {
  gettext("Linear discriminant")
}
.mlPredictionGetModelType.lm <- function(model) {
  gettext("Linear")
}
.mlPredictionGetModelType.gbm <- function(model) {
  gettext("Boosting")
}
.mlPredictionGetModelType.randomForest <- function(model) {
  gettext("Random forest")
}
.mlPredictionGetModelType.cv.glmnet <- function(model) {
  gettext("Regularized linear regression")
}
.mlPredictionGetModelType.nn <- function(model) {
  gettext("Neural network")
}
.mlPredictionGetModelType.rpart <- function(model) {
  gettext("Decision tree")
}
.mlPredictionGetModelType.svm <- function(model) {
  gettext("Support vector machine")
}
.mlPredictionGetModelType.naiveBayes <- function(model) {
  gettext("Naive Bayes")
}
.mlPredictionGetModelType.glm <- function(model) {
  gettext("Logistic regression")
}
.mlPredictionGetModelType.vglm <- function(model) {
  gettext("Multinomial regression")
}

# S3 method to make predictions using the model
.mlPredictionGetPredictions <- function(model, dataset) {
  UseMethod(".mlPredictionGetPredictions", model)
}
.mlPredictionGetPredictions.kknn <- function(model, dataset) {
  if (inherits(model, "jaspClassification")) {
    as.character(kknn:::predict.train.kknn(model[["predictive"]], dataset))
  } else if (inherits(model, "jaspRegression")) {
    as.numeric(kknn:::predict.train.kknn(model[["predictive"]], dataset))
  }
}
.mlPredictionGetPredictions.lda <- function(model, dataset) {
  as.character(MASS:::predict.lda(model, newdata = dataset)$class)
}
.mlPredictionGetPredictions.lm <- function(model, dataset) {
  as.numeric(predict(model, newdata = dataset))
}
.mlPredictionGetPredictions.gbm <- function(model, dataset) {
  if (inherits(model, "jaspClassification")) {
    tmp <- gbm:::predict.gbm(model, newdata = dataset, n.trees = model[["n.trees"]], type = "response")
    as.character(colnames(tmp)[apply(tmp, 1, which.max)])
  } else if (inherits(model, "jaspRegression")) {
    as.numeric(gbm:::predict.gbm(model, newdata = dataset, n.trees = model[["n.trees"]], type = "response"))
  }
}
.mlPredictionGetPredictions.randomForest <- function(model, dataset) {
  if (inherits(model, "jaspClassification")) {
    as.character(randomForest:::predict.randomForest(model, newdata = dataset))
  } else if (inherits(model, "jaspRegression")) {
    as.numeric(randomForest:::predict.randomForest(model, newdata = dataset))
  }
}
.mlPredictionGetPredictions.cv.glmnet <- function(model, dataset) {
  as.numeric(glmnet:::predict.cv.glmnet(model, newx = data.matrix(dataset)))
}
.mlPredictionGetPredictions.nn <- function(model, dataset) {
  if (inherits(model, "jaspClassification")) {
    as.character(levels(factor(model[["data"]][[model[["jaspVars"]][["encoded"]]$target]]))[max.col(neuralnet:::predict.nn(model, newdata = dataset))])
  } else if (inherits(model, "jaspRegression")) {
    as.numeric(neuralnet:::predict.nn(model, newdata = dataset))
  }
}
.mlPredictionGetPredictions.rpart <- function(model, dataset) {
  if (inherits(model, "jaspClassification")) {
    as.character(levels(factor(model[["data"]][[model[["jaspVars"]][["encoded"]]$target]]))[max.col(rpart:::predict.rpart(model, newdata = dataset))])
  } else if (inherits(model, "jaspRegression")) {
    as.numeric(rpart:::predict.rpart(model, newdata = dataset))
  }
}
.mlPredictionGetPredictions.svm <- function(model, dataset) {
  if (inherits(model, "jaspClassification")) {
    as.character(levels(factor(model[["data"]][[model[["jaspVars"]][["encoded"]]$target]]))[e1071:::predict.svm(model, newdata = dataset)])
  } else if (inherits(model, "jaspRegression")) {
    as.numeric(e1071:::predict.svm(model, newdata = dataset))
  }
}
.mlPredictionGetPredictions.naiveBayes <- function(model, dataset) {
  as.character(e1071:::predict.naiveBayes(model, newdata = dataset, type = "class"))
}
.mlPredictionGetPredictions.glm <- function(model, dataset) {
  as.character(levels(as.factor(model$model[[model[["jaspVars"]][["encoded"]]$target]]))[round(predict(model, newdata = dataset, type = "response"), 0) + 1])
}
.mlPredictionGetPredictions.vglm <- function(model, dataset) {
  logodds <- predict(model[["original"]], newdata = dataset)
  ncategories <- ncol(logodds) + 1
  probabilities <- matrix(0, nrow = nrow(logodds), ncol = ncategories)
  for (i in seq_len(ncategories - 1)) {
    probabilities[, i] <- exp(logodds[, i])
  }
  probabilities[, ncategories] <- 1
  row_sums <- rowSums(probabilities)
  probabilities <- probabilities / row_sums
  predicted_columns <- apply(probabilities, 1, which.max)
  as.character(levels(as.factor(model$target))[predicted_columns])
}

# S3 method to make find out number of observations in training data
.mlPredictionGetTrainingN <- function(model) {
  UseMethod(".mlPredictionGetTrainingN", model)
}
.mlPredictionGetTrainingN.kknn <- function(model) {
  nrow(model[["predictive"]]$data)
}
.mlPredictionGetTrainingN.lda <- function(model) {
  model[["N"]]
}
.mlPredictionGetTrainingN.lm <- function(model) {
  nrow(model[["model"]])
}
.mlPredictionGetTrainingN.gbm <- function(model) {
  model[["nTrain"]]
}
.mlPredictionGetTrainingN.randomForest <- function(model) {
  length(model[["y"]])
}
.mlPredictionGetTrainingN.cv.glmnet <- function(model) {
  model[["glmnet.fit"]][["nobs"]]
}
.mlPredictionGetTrainingN.nn <- function(model) {
  nrow(model[["data"]])
}
.mlPredictionGetTrainingN.rpart <- function(model) {
  nrow(model[["x"]])
}
.mlPredictionGetTrainingN.svm <- function(model) {
  length(model[["fitted"]])
}
.mlPredictionGetTrainingN.naiveBayes <- function(model) {
  nrow(model[["data"]])
}
.mlPredictionGetTrainingN.glm <- function(model) {
  nrow(model[["data"]])
}
.mlPredictionGetTrainingN.vglm <- function(model) {
  nrow(model[["x"]])
}

.mlPredictionReadModel <- function(options) {
  if (options[["trainedModelFilePath"]] != "") {
    model <- try({
      readRDS(options[["trainedModelFilePath"]])
    })
    if (!is.jaspMachineLearning(model)) {
      jaspBase:::.quitAnalysis(gettext("Error: The trained model is not created in JASP."))
    }
    if (!(any(c("kknn", "lda", "gbm", "randomForest", "cv.glmnet", "nn", "rpart", "svm", "lm", "naiveBayes", "glm", "vglm") %in% class(model)))) {
      jaspBase:::.quitAnalysis(gettextf("The trained model (type: %1$s) is currently not supported in JASP.", paste(class(model), collapse = ", ")))
    }
    if (model[["jaspVersion"]] != .baseCitation) {
      jaspBase:::.quitAnalysis(gettext("Error: The trained model is created using a different version of JASP."))
    }
  } else {
    model <- NULL
  }
  return(model)
}

# also define methods for other objects
.mlPredictionReady <- function(model, dataset, options) {
  if (!is.null(model) && !is.null(dataset)) {
    modelVars <- model[["jaspVars"]][["encoded"]]$predictors
    presentVars <- colnames(dataset)
    ready <- all(modelVars %in% presentVars)
  } else {
    ready <- FALSE
  }
  return(ready)
}

# Ensure names in prediction data match names in training data
.matchDecodedNames <- function(names, model) {
  decoded <- model[["jaspVars"]][["decoded"]]$predictors
  encoded <- model[["jaspVars"]][["encoded"]]$predictors
  matched_indices <- match(decodeColNames(names), decoded)
  names[!is.na(matched_indices)] <- encoded[matched_indices[!is.na(matched_indices)]]
  return(names)
}

.mlPredictionReadData <- function(dataset, options, model) {
  if (length(options[["predictors"]]) == 0) {
    dataset <- NULL
  } else {
    dataset <- jaspBase::excludeNaListwise(dataset, options[["predictors"]])
    if (options[["scaleVariables"]] && length(unlist(options[["predictors"]])) > 0) {
      dataset <- .scaleNumericData(dataset)
    }
    # Select only the predictors in the model to prevent accidental double column names
    dataset <- dataset[, which(decodeColNames(colnames(dataset)) %in% model[["jaspVars"]][["decoded"]]$predictors), drop = FALSE]
    # Ensure the column names in the dataset match those in the training data
    colnames(dataset) <- .matchDecodedNames(colnames(dataset), model)
    # Retrieve the training set
    trainingSet <- model[["explainer"]]$data
    # Check for factor levels in the test set that are not in the training set
    .checkForNewFactorLevelsInPredictionSet(trainingSet, dataset, "prediction", model)
    # Ensure factor variables in dataset have same levels as those in the training data
    factorColumns <- colnames(dataset)[sapply(dataset, is.factor)]
    dataset[factorColumns] <- lapply(factorColumns, function(i) factor(dataset[[i]], levels = levels(trainingSet[[i]])))
  }
  return(dataset)
}

.mlPredictionsState <- function(model, dataset, options, jaspResults, ready) {
  if (!is.null(jaspResults[["predictions"]])) {
    return(jaspResults[["predictions"]]$object)
  } else {
    if (ready) {
      dataset <- dataset[which(colnames(dataset) %in% model[["jaspVars"]][["encoded"]]$predictors)]
      jaspResults[["predictions"]] <- createJaspState(.mlPredictionGetPredictions(model, dataset))
      jaspResults[["predictions"]]$dependOn(options = c("loadPath", "predictors", "scaleVariables"))
      return(jaspResults[["predictions"]]$object)
    } else {
      return(NULL)
    }
  }
}

.mlPredictionModelSummaryTable <- function(model, dataset, options, jaspResults, ready, position) {
  if (is.null(model)) {
    table <- createJaspTable(gettext("Loaded Model"))
  } else {
    if (inherits(model, "jaspClassification")) {
      purpose <- gettext("Classification")
    }
    if (inherits(model, "jaspRegression")) {
      purpose <- gettext("Regression")
    }
    table <- createJaspTable(gettextf("Loaded Model: %1$s", purpose))
  }
  table$dependOn(options = c("predictors", "trainedModelFilePath"))
  table$position <- position
  table$addColumnInfo(name = "model", title = gettext("Method"), type = "string")
  jaspResults[["modelSummaryTable"]] <- table
  if (is.null(model)) {
    return()
  }
  modelVars_encoded <- model[["jaspVars"]][["encoded"]]$predictors
  modelVars_decoded <- model[["jaspVars"]][["decoded"]]$predictors
  presentVars_encoded <- colnames(dataset)
  presentVars_decoded <- decodeColNames(options[["predictors"]])
  if (!all(modelVars_decoded %in% presentVars_decoded)) {
    missingVars <- modelVars_decoded[which(!(modelVars_decoded %in% presentVars_decoded))]
    table$addFootnote(gettextf("The trained model is not applied because the the following features are missing: <i>%1$s</i>.", paste0(missingVars, collapse = ", ")))
  }
  if (!all(presentVars_decoded %in% modelVars_decoded)) {
    unusedVars <- presentVars_decoded[which(!(presentVars_decoded %in% modelVars_decoded))]
    table$addFootnote(gettextf("The following features are unused because they are not a feature variable in the trained model: <i>%1$s</i>.", paste0(unusedVars, collapse = ", ")))
  }
  if (inherits(model, "kknn")) {
    table$addColumnInfo(name = "nn", title = gettext("Nearest Neighbors"), type = "integer")
  } else if (inherits(model, "lda")) {
    table$addColumnInfo(name = "ld", title = gettext("Linear Discriminants"), type = "integer")
  } else if (inherits(model, "gbm")) {
    table$addColumnInfo(name = "trees", title = gettext("Trees"), type = "integer")
    table$addColumnInfo(name = "shrinkage", title = gettext("Shrinkage"), type = "number")
  } else if (inherits(model, "randomForest")) {
    table$addColumnInfo(name = "trees", title = gettext("Trees"), type = "integer")
    table$addColumnInfo(name = "mtry", title = gettext("Features per split"), type = "integer")
  } else if (inherits(model, "cv.glmnet")) {
    table$addColumnInfo(name = "lambda", title = "\u03BB", type = "number")
  } else if (inherits(model, "glm") || inherits(model, "vglm")) {
    table$addColumnInfo(name = "family", title = gettext("Family"), type = "string")
    table$addColumnInfo(name = "link", title = gettext("Link"), type = "string")
  }
  table$addColumnInfo(name = "ntrain", title = gettext("n(Train)"), type = "integer")
  table$addColumnInfo(name = "nnew", title = gettext("n(New)"), type = "integer")
  row <- list()
  row[["model"]] <- .mlPredictionGetModelType(model)
  row[["ntrain"]] <- .mlPredictionGetTrainingN(model)
  if (inherits(model, "kknn")) {
    row[["nn"]] <- model[["predictive"]]$best.parameters$k
  } else if (inherits(model, "lda")) {
    row[["ld"]] <- ncol(model[["scaling"]])
  } else if (inherits(model, "gbm")) {
    row[["trees"]] <- model[["n.trees"]]
    row[["shrinkage"]] <- model[["shrinkage"]]
  } else if (inherits(model, "randomForest")) {
    row[["trees"]] <- model[["ntree"]]
    row[["mtry"]] <- model[["mtry"]]
  } else if (inherits(model, "cv.glmnet")) {
    row[["lambda"]] <- model[["lambda.min"]]
  } else if (inherits(model, "glm")) {
    row[["family"]] <- gettext("Binomial")
    row[["link"]] <- paste0(toupper(substr(model[["link"]], 1, 1)), substr(model[["link"]], 2, nchar(model[["link"]])))
  } else if (inherits(model, "vglm")) {
    row[["family"]] <- gettext("Multinomial")
    row[["link"]] <- gettext("Logit")
  }
  if (length(presentVars_encoded) > 0) {
    row[["nnew"]] <- nrow(dataset)
  }
  table$addRows(row)
}

.mlPredictionsTable <- function(model, dataset, options, jaspResults, ready, position) {
  if (!is.null(jaspResults[["predictionsTable"]]) || !options[["predictionsTable"]]) {
    return()
  }
  table <- createJaspTable(gettext("Predictions for New Data"))
  table$dependOn(options = c("predictors", "trainedModelFilePath", "predictionsTable", "predictionsTableFeatures", "scaleVariables", "fromIndex", "toIndex"))
  table$position <- position
  table$addColumnInfo(name = "row", title = gettext("Case"), type = "integer")
  if (!is.null(model) && inherits(model, "jaspClassification")) {
    table$addColumnInfo(name = "pred", title = gettext("Predicted"), type = "string")
  } else {
    table$addColumnInfo(name = "pred", title = gettext("Predicted"), type = "number")
  }
  jaspResults[["predictionsTable"]] <- table
  if (!ready) {
    return()
  }
  predictions <- .mlPredictionsState(model, dataset, options, jaspResults, ready)
  indexes <- options[["fromIndex"]]:options[["toIndex"]]
  selection <- predictions[indexes]
  cols <- list(row = indexes, pred = selection)
  if (options[["predictionsTableFeatures"]]) {
    modelVars_encoded <- model[["jaspVars"]][["encoded"]]$predictors
    modelVars_decoded <- model[["jaspVars"]][["decoded"]]$predictors
    matched_names <- match(colnames(dataset), modelVars_encoded)
    for (i in seq_len(ncol(dataset))) {
      colName <- modelVars_decoded[matched_names[i]]
      if (is.factor(dataset[[i]])) {
        table$addColumnInfo(name = colName, title = colName, type = "string")
        var <- levels(dataset[[i]])[dataset[[i]]]
      } else {
        table$addColumnInfo(name = colName, title = colName, type = "number")
        var <- dataset[[i]]
      }
      var <- var[indexes]
      cols[[colName]] <- var
    }
  }
  table$setData(cols)
}

.mlPredictionsAddPredictions <- function(model, dataset, options, jaspResults, ready) {
  if (options[["addPredictions"]] && is.null(jaspResults[["predictionsColumn"]]) && options[["predictionsColumn"]] != "" && ready) {
    predictionsColumn <- rep(NA, max(as.numeric(rownames(dataset))))
    predictionsColumn[as.numeric(rownames(dataset))] <- .mlPredictionsState(model, dataset, options, jaspResults, ready)
    jaspResults[["predictionsColumn"]] <- createJaspColumn(columnName = options[["predictionsColumn"]])
    jaspResults[["predictionsColumn"]]$dependOn(options = c("predictionsColumn", "predictors", "trainedModelFilePath", "scaleVariables", "addPredictions"))
    if (inherits(model, "jaspClassification")) jaspResults[["predictionsColumn"]]$setNominal(predictionsColumn)
    if (inherits(model, "jaspRegression")) jaspResults[["predictionsColumn"]]$setScale(predictionsColumn)
  }
}
