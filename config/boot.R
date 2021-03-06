# It wrought itself from the void, defying the laws which govern
# (1) existence and (2) other such matters.

if (!isTRUE(director$cache_get("bootstrapped"))) {
  # Register the controllers controller explicitly.
  director$register_parser("lib/controllers",
    director$resource("lib/controllers/controller")
  )

  # Fetch the preprocessor and parser for the routes.
  routes <- director$resource("lib/controllers/routes")

  # Register the routes parser on the routes file explicitly.
  director$register_parser("config/routes", routes$parser)

  # Setup config directory.
  config <- director$resource("lib/controllers/config")
  director$register_parser("config", config$parser)

  # Now load the routes, which will bring in all the other controllers.
  director$resource("config/routes")
}

