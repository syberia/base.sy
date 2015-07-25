# When the base engine is included in another engine, auto-source config/routes.
.onAttach <- function(parent_engine) {
  # `director` is the base engine object.

  parent_engine$register_parser("lib/controllers",
    director$resource("lib/controllers/controller")$parser, overwrite = TRUE)

  routes <- director$resource("lib/controllers/routes")

  parent_engine$register_parser("config/routes", routes$parser, overwrite = TRUE)

  # TODO: (RK) Fix this hack using a proper helper resource.
  #environment(routes$preprocessor)$mount(parent_engine)(director)

  parent_engine$resource("config/routes")
}

