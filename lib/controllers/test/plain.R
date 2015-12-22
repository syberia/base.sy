# The default preprocessor for syberia test environments.
preprocessor <- function(resource, director, source_env, source, filename, args) {
  tested_resource <- gsub("^test\\/", "", resource)

  # Provide access to the director for people with hardcore test setup
  # and teardown hooks.

  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("Please install ", crayon::yellow("testthat"), call. = FALSE)
  }

  make_tested_resource <- function(...) {
    if (is(director, "syberia_engine")) {
      director$resource(tested_resource, ..., children. = FALSE, parent. = FALSE)
    } else {
      director$resource(tested_resource, ...)
    }
  }

  force(resource)
  source_env$resource <- function(name, ...) {
    if (missing(name)) {
      make_tested_resource(resource, ...)
    } else {
      make_tested_resource(...)
    }
  }

  test_args <- list(filename, env = source_env)

  if (is.element("reporter", names(args))) {
    test_args$reporter <- args$reporter
    test_args$start_end_reporter <- FALSE
  }

  testthat::context(tested_resource)
  do.call(testthat::test_file, test_args)
}

# No parser.
function() { }
