function(director, resource_object, output) {
  error <- function(...) {
    stop("In your ", crayon::red("config/routes.R"), " file in the ",
         "syberia project at ", sQuote(crayon::blue(director$.root)),
         ' ', ..., call. = FALSE)
  }

  if (!is.list(output)) {
    error("you should return a list (put it at the end of the file). ",
         "Currently, you have something of type ", sQuote(class(output)[1]), ".")
    # TODO: (RK) More informative message here.
  }

  if (length(output) > 0 &&
      (any(sapply(names(output), function(n) !isTRUE(nzchar(n)))) ||
       length(unique(names(output))) != length(output))) {
    error(" your list of routes needs to have unique prefixes.")
    # TODO: (RK) Provide better information about name duplication or missing names.
  }

  # Only parse the routes file if it has changed, or the project has not
  # been bootstrapped.
  if (resource_object$any_dependencies_modified() ||
      !isTRUE(director$.cache$bootstrapped)) {
    lapply(names(output), function(route) {
      controller <- output[[route]]
      if (!is.character(controller) && !is.function(controller)) {
        error("Every route must be a character or a function (your route ",
              crayon::yellow(sQuote(route)), " is of type ",
              sQuote(class(controller)[1]), ")")
      }

      if (is.character(controller)) {
        director$.cache$routes[[route]] <- director$.cache$routes[[route]] %||% character(0)
        director$.cache$routes[[route]] <- c(director$.cache$routes[[route]], controller)

        controller <- director$resource(file.path('lib', 'controllers', controller))
        controller <- controller$value()
      } else if (is.function(controller)) controller <- list(parser = controller)

      director$register_parser(route, controller$parser, cache = isTRUE(controller$cache))
      if (is.function(controller$preprocessor)) {
        director$register_preprocessor(route, controller$preprocessor)
      }
      # TODO: (RK) More validations on routes?
    })
  }
  TRUE
}

