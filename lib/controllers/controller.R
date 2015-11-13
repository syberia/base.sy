function(input, resource) {
  ## When the director package is loaded using `devtools::load_all`,
  ## it imports a symbol called `exists`. We use explicit base namespacing
  ## to avoid conflicts during development.
  if (base::exists('preprocessor', envir = input, inherits = FALSE) &&
      !is.function(input$preprocessor))
    stop("The preprocessor defined in ",
         sQuote(crayon::red(resource)),
         " must be a function, but instead is of class ",
         sQuote(class(input$preprocessor[1])), call. = FALSE)
  list(parser = output, preprocessor = input$preprocessor,
       cache = isTRUE(input$cache), test = !identical(FALSE, input$test))
}

