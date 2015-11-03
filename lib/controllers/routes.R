#' Merge two lists and overwrite latter entries with former entries
#' if names are the same.
#'
#' For example, \code{list_merge(list(a = 1, b = 2), list(b = 3, c = 4))}
#' will be \code{list(a = 1, b = 3, c = 4)}.
#' @param list1 list
#' @param list2 list
#' @return the merged list.
#' @examples
#' @export
#' stopifnot(identical(list_merge(list(a = 1, b = 2), list(b = 3, c = 4)),
#'                     list(a = 1, b = 3, c = 4)))
#' stopifnot(identical(list_merge(NULL, list(a = 1)), list(a = 1)))
list_merge <- function(list1, list2) {
  list1 <- list1 %||% list()
  # Pre-allocate memory to make this slightly faster.
  list1[Filter(function(x) nchar(x) > 0, names(list2) %||% c())] <- NULL
  for (i in seq_along(list2)) {
    name <- names(list2)[i]
    if (!identical(name, NULL) && !identical(name, "")) list1[[name]] <- list2[[i]]
    else list1 <- append(list1, list(list2[[i]]))
  }
  list1
}

error <- function(director) {
  function(...) {
    stop("In your ", crayon::red("config/routes.R"), " file in the ",
         "syberia project at ", sQuote(crayon::blue(director$root())),
         ' ', ..., call. = FALSE)
  }
}

subroutes <- function(engine) {
  # We must grab the child engine routes file, without looking back up
  # to the parent.
  engine$resource("config/routes", parse. = FALSE, parent. = FALSE)
}

function(director, output, any_dependencies_modified, args) {
  # Merge on the routes of the subengines.
  # TODO: (RK) Depth-2+ routes merging?
  if (!identical(args$recursive, FALSE)) {
    output <- list_merge(Reduce(list_merge,
      lapply(director$.engines, function(engine) {
        subroutes(engine$engine)
      })), output)
  }

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
  if (isTRUE(args$force) ||
      !isTRUE(director$cache_get("bootstrapped")) ||
      director$resource(resource, modification_tracker.touch = FALSE,
                        dependency_tracker.return = "any_dependencies_modified")) {
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

        # We need to provide a defining_environment to avoid parent.env(topenv())
        # = emptyenv() issues while sourced within a package namespace.
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

