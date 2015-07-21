# When the base engine is included in another engine, auto-source config/routes.
.onAttach <- function(parent_engine) {
  # `director` is the base engine object.
  routes <- director$resource("lib/controllers/routes")$value()

  parent_engine$register_preprocessor("config/routes", routes$preprocessor, overwrite = TRUE)
  parent_engine$register_parser("config/routes", routes$parser, overwrite = TRUE)

  # TODO: (RK) Fix this hack using a proper helper resource.
  environment(routes$preprocessor)$mount(parent_engine)(director)

  parent_engine$resource("config/routes")$value()
}

