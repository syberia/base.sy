# The tests controller - used by default for all tests in a
# syberia engine / top-level project.

preprocessor <- function(resource, director, source_env, source) {
  tested_resource <- gsub("^test\\/", "", resource)
  if (!director$exists(tested_resource)) {
    # TODO: (RK) Figure out how this interacts with virtual resources.
    #warning("You are testing ", sQuote(crayon::yellow(tested_resource)),
    #        " but it does not exist in the project.\n", call. = FALSE, immediate = TRUE)
    #return(NULL)
  }

  requireNamespace("testthat", quietly = TRUE)
  testthat::context(tested_resource)
  source_env$resource <- function(...) director$resource(tested_resource, recompile. = TRUE)
  source()
}

function(output) { output }

