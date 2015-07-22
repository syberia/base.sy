error <- function(director) {
  function(...) {
    stop("In your ", crayon::red("config/routes.R"), " file in the ",
         "syberia project at ", sQuote(crayon::blue(director$.root)),
         ' ', ..., call. = FALSE)
  }
}

mount <- function(director) {
  force(director)
  error <- error(director)
  function(engine, path = "") {
    is.simple_string <- function(x) {
      is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)
    }

    if (!is(engine, "director") && !is.simple_string(engine)) {
      error("you provided an invalid engine to mount. Please ",
            "provide a single string.")
    }

    if (!identical(path, "") && !is.simple_string(path)) {
      error("you provided an invalid path to mount the ",
            if (is.character(engine)) sQuote(crayon::yellow(engine)),
            " engine. Please provide a single string.")
    }

    # TODO: (RK) Make this less hacky.
    if (!is.environment(director$.cache$engines)) {
      error("you attempted to mount an engine, but you have not defined ",
            "any engines in the ", sQuote(crayon::blue("config/engines.R")),
            " file.")
    }

    if (is.character(engine) && !is.element(engine, ls(director$.cache$engines, all = TRUE))) {
      error("you mounted the engine ",
            if (is.character(engine)) sQuote(crayon::red(engine)),
            ", but it is not defined in the",
            sQuote(crayon::blue("config/engines.R")), " file.")
    }

    # TODO: (RK) Slay this blatant violation of Demeter's laws that follows.
    if (!is(engine, "director")) {
      engine <- director$.cache$engines[[engine]]
    }

    for (route in names(engine$.parsers)) {
      director$register_parser(
        paste0(path, route), engine$.parsers[[route]], overwrite = TRUE)
    }

    for (route in names(engine$.preprocessors)) {
      director$register_preprocessor(
        paste0(path, route), engine$.preprocessors[[route]], overwrite = TRUE)
    }
  }
}

preprocessor <- function(source_env, source, director) {
  error <- error(director)
  source_args$local$mount <- mount(director)
  source()
}

function(director, output, any_dependencies_modified) {
  error <- error(director)
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
  if (director$resource(resource, modification_tracker.touch = FALSE,
                        dependency_tracker.return = "any_dependencies_modified") ||
      !isTRUE(director$cache_get("bootstrapped"))) {
    lapply(names(output), function(route) {
      controller <- output[[route]]
      if (!is.character(controller) && !is.function(controller)) {
        error("Every route must be a character or a function (your route ",
              crayon::yellow(sQuote(route)), " is of type ",
              sQuote(class(controller)[1]), ")")
      }

      if (is.character(controller)) {
        routes <- director$cache_get("routes") %||% list()
        new_route <- routes[[route]]
        new_route <- c(new_route, controller)
        routes[[route]] <- new_route
        director$cache_set("routes", routes)

        controller <- director$resource(file.path('lib', 'controllers', controller),
                                        defining_environment. = new.env(parent = environment()))
      } else if (is.function(controller)) controller <- list(parser = controller)

      director$register_parser(route, controller$parser,
                               cache = isTRUE(controller$cache), overwrite = TRUE)
      if (is.function(controller$preprocessor)) {
        director$register_preprocessor(route, controller$preprocessor, overwrite = TRUE)
      }
      # TODO: (RK) More validations on routes?
    })
  }
  TRUE
}

