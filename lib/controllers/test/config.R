# The default preprocessor for syberia test environments.
preprocessor <- function(director, source_env, source) {
  # Provide access to the director for people with hardcore test setup
  # and teardown hooks.
  source_env$director <- director 
  source()
}

# No parser.
function(input) {
  if (length(input) > 0L) {
    as.list(input)
  } else {
    list()
  }
}

