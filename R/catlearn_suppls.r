

# model_accuracy
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#'
#' Produces classification probability for the target class, by item or by block.
#'
#' @param tr Matrix used to train the model.
#' @param out_probs Matrix of output probabilities produced by the model.
#' @param blocks Boolean to toggle block averaged classification probabilities, default is TRUE
#' @return Vector of classification probabilities for the target class
#' @example model_accuracy(tr, out_probs, blocks = TRUE)
#' @export

model_accuracy <- function(tr, out_probs, blocks = TRUE) {
  n_trials <- dim(tr)[1]
  all_cols <- colnames(tr)

  # find the target columns and correct class
  targets <-
    substr(all_cols, 1, 1) == 't' &
      is.finite(
        suppressWarnings(
          as.numeric(substr(all_cols, 2, 2))))
  target_cols <- apply(tr[,targets], 1, which.max)

  # get probability of correct class
  class_prob <- rep(NA, n_trials)
  for (i in 1:n_trials) {
    class_prob[i] <- out_probs[i, target_cols[i]]
  }

  # get probability averaged for each block
  if (blocks == TRUE) {
    tr_comp  <- cbind(tr, class_prob)
    n_blocks <- max(tr_comp[,'block'])
    blk_avg <- rep(NA, n_blocks)

    # average for each block
    for (i in 1:n_blocks) {
      blk_avg[i] <-
        mean(tr_comp[tr_comp[,'block'] == i,'class_prob'])
    }
    return(blk_avg)
  }
  return(class_prob)
}


# generate_state
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#'
#' Construct the state list
#'
#' @param input Complete matrix of inputs for training
#' @param categories Vector of category assignment values
#' @param colskip Scalar for number of columns to skip in the tr matrix
#' @param continuous Boolean value indicating if inputs are continuous
#' @param make_wts Boolean value indicating if initial weights should be generated
#' @param wts_range Scalar value for the range of the generated weights
#' @param wts_center Scalar value for the center of the weights
#' @param num_hids Scalar value for the number of hidden units in the model architecture
#' @param learning_rate Learning rate for weight updates through backpropagation
#' @param beta_val Scalar value for the beta parameter
#' @param model_seed Scalar value to set the random seed
#' @return List of the model hyperparameters and weights (by request)
#' @example generate_state()
#' @export

generate_state <- function(input, categories, colskip, continuous, make_wts,
  wts_range = NULL,  wts_center    = NULL,
  num_hids  = NULL,  learning_rate = NULL,
  beta_val  = NULL,  model_seed    = NULL) {

  # # # input variables
  num_cats  <- length(unique(categories))
  num_feats <- dim(input)[2]

  # # # assign default values if needed
  if (is.null(wts_range))      wts_range     <- 1
  if (is.null(wts_center))     wts_center    <- 0
  if (is.null(num_hids))       num_hids      <- 3
  if (is.null(learning_rate))  learning_rate <- 0.15
  if (is.null(beta_val))       beta_val      <- 0
  if (is.null(model_seed))     model_seed    <- runif(1) * 100000 * runif(1)

  # # # initialize weight matrices
  if (make_wts == TRUE) {
    wts <- get_wts(num_feats, num_hids, num_cats, wts_range, wts_center)
  } else {
    wts <- list(in_wts = NULL, out_wts = NULL)
  }

  return(st = list(num_feats = num_feats, num_cats = num_cats, colskip = colskip,
    continuous = continuous, wts_range = wts_range, wts_center = wts_center,
    num_hids = num_hids, learning_rate = learning_rate, beta_val = beta_val,
    model_seed = model_seed, in_wts = wts$in_wts, out_wts = wts$out_wts))

}

# get_test_inputs
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#'
#' Function to grab inputs that might be useful for model testing
#'
#' @param target_cats Variable to choose a category, unifr (unfr1 and unfr2
#'     for autoencoder), type# (Shepard, Hovland and Jenkin's elemental
#'     types, e.g., type2, type 3, ...), multiclass (4 class problem, shj type 2)
#' @example get_test_inputs()
#' @export

get_test_inputs <- function(target_cats){

  test_inputs <-
    list(
      unifr = list(ins = matrix(c(
      1,  1,  1,  1,
      1,  1, -1,  1,
      1, -1,  1,  1,
     -1,  1,  1,  1,
     -1, -1, -1, -1,
     -1, -1,  1, -1,
     -1,  1, -1, -1,
      1, -1, -1, -1), ncol = 4, byrow = TRUE),
      labels = c(1, 1, 1, 1, 2, 2, 2, 2)),

      unifr1 = list(ins = matrix(c(
      1,  1,  1,  1,
      1,  1, -1,  1,
      1, -1,  1,  1,
     -1,  1,  1,  1), ncol = 4, byrow = TRUE),
      labels = c(1, 1, 1, 1)),

      unifr2 = list(ins = matrix(c(
     -1, -1, -1, -1,
     -1, -1,  1, -1,
     -1,  1, -1, -1,
      1, -1, -1, -1), ncol = 4, byrow = TRUE),
      labels = c(1, 1, 1, 1)),

      type1 = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(1, 1, 1, 1, 2, 2, 2, 2)),

      type2 = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(1, 1, 2, 2, 2, 2, 1, 1)),

      type3 = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(1, 1, 2, 1, 1, 2, 2, 2)),

      type4 = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(1, 1, 1, 2, 1, 2, 2, 2)),

      type5 = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(2, 1, 1, 1, 1, 2, 2, 2)),

      type6 = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(1, 2, 2, 1, 2, 1, 1, 2)),

      multiclass = list(ins = matrix(c(
     -1, -1, -1,
     -1, -1,  1,
     -1,  1, -1,
     -1,  1,  1,
      1, -1, -1,
      1, -1,  1,
      1,  1, -1,
      1,  1,  1),  ncol = 3, byrow = TRUE),
      labels = c(1, 1, 2, 2, 3, 3, 4, 4)))

  target_cat <- test_inputs[[target_cats]]

  return(target_cat)
}

# plot_training
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#'
#' plots training data
#' plot_training()
# plot_training <- function()

# tr_init
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#'
#' Initialize a tr object
#'
#' @param n_feats Number of features (integer, > 0)
#' @param feature_type String type: numeric (default), logical, etc
#' @return An initialized dataframe with the appropriate columns
#' @example tr_init()
#' @export

tr_init <- function(n_feats, n_cats, feature_type = 'numeric') {

  feature_cols <- list()
  for(f in 1:n_feats) {
    feature_cols[[paste0('f', f)]] = feature_type
  }

  target_cols <- list()
  for(c in 1:n_cats) {
   target_cols[[paste0('t', c)]] = 'integer'
  }

  other_cols <- list(
    ctrl = 'integer',
    trial = 'integer',
    block = 'integer',
    example = 'integer'
  )

  all_cols <- append(other_cols, c(feature_cols, target_cols))

  # create empty df with column types specified by all_cols
  empty_tr <- data.frame()
  for (col in names(all_cols)) {
      empty_tr[[col]] <- vector(mode = all_cols[[col]], length = 0)
  }

  empty_tr <- as.matrix(empty_tr)

  return(empty_tr)
}

# tr_add
#  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #  #
#'
#' Add trials to an initialized tr object
#'
#' @param inputs Matrix of feature values for each item
#' @param tr Initialized trial object
#' @param labels Integer class labels for each input. Default NULL
#' @param blocks Integer number of repetitions. Default 1
#' @param shuffle Boolean, shuffle each block. Default FALSE
#' @param ctrl Integer control parameter, applying to all inputs. Default 2
#' @param reset Boolean, reset state on first trial (ctrl=1). Default FALSE
#' @return An updated dataframe
#' @example tr_add()
#' @export

tr_add <- function(inputs, tr,
  labels = NULL,
  blocks = 1,
  ctrl = NULL,
  shuffle = FALSE,
  reset = FALSE) {

  # some constants
  numinputs <- dim(inputs)[1]
  numfeatures <- dim(inputs)[2]
  numtrials <- numinputs * blocks

  # obtain labels vector if needed
  if (is.null(labels)) labels <- rep(NA, numinputs)

  # generate order of trials
  if (shuffle) {
    examples <- as.vector(apply(replicate(blocks,seq(1, numinputs)), 2,
      sample, numinputs))
  } else{
    examples <- as.vector(replicate(blocks, seq(1, numinputs)))
  }

  # create rows for tr
  rows <- list(
    ctrl = rep(ctrl, numtrials),
    trial = 1:numtrials,
    block = sort(rep(1:blocks, numinputs)),
    example = examples
  )
#
  # add features to rows list
  for(f in 1:numfeatures){
    rows[[paste0('f', f)]] <- inputs[examples, f]
  }

  # add category labels
  num_cats <- max(labels)
  label_mat <- matrix(-1, ncol = num_cats, nrow = numtrials)

  for (i in 1:numtrials) {
    label_mat[i, labels[examples[i]]] <- 1
  }

  rows <- data.frame(rows)
  rows <- cbind(rows, label_mat)

  # reset on first trial if needed
  if (reset) {rows$ctrl[1] <- 1}

  rows <- as.matrix(rows)
  return(rbind(tr, rows))
}
