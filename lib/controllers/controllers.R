function(input, resource) {
  if (exists('preprocessor', envir = input, inherits = FALSE) &&
      !is.function(input$preprocessor))
    stop("The preprocessor defined in ",
         sQuote(crayon::red(resource)),
         " must be a function, but instead is of class ",
         sQuote(class(input$preprocessor[1])), call. = FALSE)
  list(parser = output, preprocessor = input$preprocessor,
       cache = isTRUE(input$cache), test = !identical(FALSE, input$test))
}

