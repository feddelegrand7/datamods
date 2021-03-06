
#' @title Import data from Global Environment
#'
#' @description Let the user select a dataset from its own environment.
#'
#' @param id Module's ID.
#' @param globalenv Search for data in Global environment.
#' @param packages Name of packages in which to search data.
#'
#' @return
#'  * UI: HTML tags that can be included in shiny's UI
#'  * Server: a \code{list} with two slots:
#'    + **data**: a \code{reactive} function returning the selected \code{data.frame}.
#'    + **name**: a \code{reactive} function the name of the selected data as \code{character}.
#'
#'
#'
#' @export
#'
#' @name import-globalenv
#'
#' @importFrom htmltools tags
#' @importFrom shiny NS actionButton icon textInput
#' @importFrom shinyWidgets pickerInput alert
#'
#' @example examples/globalenv-default.R
import_globalenv_ui <- function(id, globalenv = TRUE, packages = get_data_packages()) {

  ns <- NS(id)

  choices <- list()
  if (isTRUE(globalenv)) {
    choices <- append(choices, "Global Environment")
  }
  if (!is.null(packages)) {
    choices <- append(choices, list(Packages = as.character(packages)))
  }

  if (isTRUE(globalenv)) {
    selected <- "Global Environment"
  } else {
    selected <- packages[1]
  }

  tags$div(
    class = "datamods-import",
    html_dependency_datamods(),
    tags$h3("Import a dataset"),
    pickerInput(
      inputId = ns("data"),
      label = "Select a data.frame:",
      choices = NULL,
      options = list(title = "List of data.frame..."),
      width = "100%"
    ),
    pickerInput(
      inputId = ns("env"),
      label = "Select an environment in which to search:",
      choices = choices,
      selected = selected,
      width = "100%",
      options = list(
        "title" = "Select environment",
        "live-search" = TRUE,
        "size" = 10
      )
    ),

    tags$div(
      id = ns("import-placeholder"),
      alert(
        id = ns("import-result"),
        status = "info",
        tags$b("No data selected!"),
        "Use a data.frame from user environment",
        dismissible = TRUE
      )
    ),
    tags$div(
      id = ns("validate-button"),
      style = "margin-top: 20px;",
      actionButton(
        inputId = ns("validate"),
        label = "Import selected data",
        icon = icon("arrow-circle-right"),
        width = "100%",
        disabled = "disabled",
        class = "btn-primary"
      )
    )
  )
}




#' @param trigger_return When to update selected data:
#'  \code{"button"} (when user click on button) or
#'  \code{"change"} (each time user select a dataset in the list).
#' @param return_class Class of returned data: \code{data.frame}, \code{data.table} or \code{tbl_df} (tibble).
#'
#' @export
#'
#' @importFrom shiny moduleServer reactiveValues observeEvent reactive removeUI is.reactive icon actionLink
#' @importFrom htmltools tags tagList
#' @importFrom shinyWidgets updatePickerInput
#'
#' @rdname import-globalenv
import_globalenv_server <- function(id,
                                    trigger_return = c("button", "change"),
                                    return_class = c("data.frame", "data.table", "tbl_df")) {

  trigger_return <- match.arg(trigger_return)

  module <- function(input, output, session) {

    ns <- session$ns

    imported_rv <- reactiveValues(data = NULL, name = NULL)
    temporary_rv <- reactiveValues(data = NULL, name = NULL)


    observeEvent(input$env, {
      if (identical(input$env, "Global Environment")) {
        choices <- search_obj("data.frame")
      } else {
        choices <- list_pkg_data(input$env)
      }
      if (is.null(choices)) {
        choices <- "No data.frame here..."
        choicesOpt <- list(disabled = TRUE)
      } else {
        choicesOpt <- list(
          subtext = get_dimensions(choices)
        )
      }
      temporary_rv$package <- attr(choices, "package")
      updatePickerInput(
        session = session,
        inputId = "data",
        choices = choices,
        choicesOpt = choicesOpt
      )
    })


    # if (is.reactive(choices)) {
    #   observeEvent(choices(), {
        # updatePickerInput(
        #   session = session,
        #   inputId = "data",
        #   choices = choices(),
        #   selected = temporary_rv$name,
        #   choicesOpt = list(
        #     subtext = get_dimensions(choices())
        #   )
        # )
    #     temporary_rv$package <- attr(choices(), "package")
    #   })
    # } else {
    #   updatePickerInput(
    #     session = session,
    #     inputId = "data",
    #     choices = choices,
    #     selected = selected,
    #     choicesOpt = list(
    #       subtext = get_dimensions(choices)
    #     )
    #   )
    #   temporary_rv$package <- attr(choices, "package")
    # }


    observeEvent(input$trigger, {
      if (identical(trigger_return, "change")) {
        hideUI(selector = paste0("#", ns("validate-button")))
      }
    })


    observeEvent(input$data, {
      req(input$data)
      name_df <- input$data

      if (!is.null(temporary_rv$package)) {
        attr(name_df, "package") <- temporary_rv$package
      }

      imported <- try(get_env_data(name_df), silent = TRUE)

      if (inherits(imported, "try-error") || NROW(imported) < 1) {

        toggle_widget(inputId = "validate", enable = FALSE)

        insert_alert(
          selector = ns("import"),
          status = "danger",
          tags$b(icon("exclamation-triangle"), "Ooops"), "Something went wrong..."
        )

      } else {

        toggle_widget(inputId = "validate", enable = TRUE)

        if (identical(trigger_return, "button")) {
          success_message <- tagList(
            tags$b(icon("check"), "Data ready to be imported!"),
            sprintf(
              "%s: %s obs. of %s variables imported",
              input$data, nrow(imported), ncol(imported)
            )
          )
        } else {
          success_message <- tagList(
            tags$b(icon("check"), "Data successfully imported!"),
            sprintf(
              "%s: %s obs. of %s variables imported",
              input$data, nrow(imported), ncol(imported)
            )
          )
        }
        success_message <- tagList(
          success_message,
          tags$br(),
          actionLink(
            inputId = ns("see_data"),
            label = "click to see data",
            icon = icon("hand-o-right")
          )
        )
        insert_alert(
          selector = ns("import"),
          status = "success",
          success_message
        )

        temporary_rv$data <- imported
        temporary_rv$name <- input$data
      }
    }, ignoreInit = TRUE)


    observeEvent(input$see_data, {
      show_data(temporary_rv$data)
    })

    observeEvent(input$validate, {
      imported_rv$data <- temporary_rv$data
      imported_rv$name <- temporary_rv$name
    })


    if (identical(trigger_return, "button")) {
      return(list(
        data = reactive(as_out(imported_rv$data, return_class)),
        name = reactive(imported_rv$name)
      ))
    } else {
      return(list(
        data = reactive(as_out(temporary_rv$data, return_class)),
        name = reactive(temporary_rv$name)
      ))
    }
  }

  moduleServer(
    id = id,
    module = module
  )
}







# utils -------------------------------------------------------------------


#' Get packages containing datasets
#'
#' @return a character vector of packages names
#' @export
#'
#' @importFrom utils data
#'
#' @examples
#' get_data_packages()
get_data_packages <- function() {
  suppressWarnings({
    pkgs <- data(package = .packages(all.available = TRUE))
  })
  unique(pkgs$results[, 1])
}


#' List dataset contained in a package
#'
#' @param pkg Name of the package, must be installed.
#'
#' @return a \code{character} vector or \code{NULL}.
#' @export
#'
#' @importFrom utils data
#'
#' @examples
#'
#' list_pkg_data("ggplot2")
list_pkg_data <- function(pkg) {
  if (isTRUE(requireNamespace(pkg, quietly = TRUE))) {
    list_data <- data(package = pkg, envir = environment())$results[, "Item"]
    attr(list_data, "package") <- pkg
    if (length(list_data) < 1) {
      NULL
    } else {
      unname(list_data)
    }
  } else {
    NULL
  }
}

#' @importFrom utils data
get_env_data <- function(obj, env = globalenv()) {
  obj <- gsub(pattern = "\\s.*", replacement = "", x = obj)
  if (obj %in% ls(name = env)) {
    get(x = obj, envir = env)
  } else if (!is.null(attr(obj, "package")) && !identical(attr(obj, "package"), "")) {
    get(utils::data(list = obj, package = attr(obj, "package"), envir = environment()))
  } else {
    NULL
  }
}


get_dimensions <- function(objs) {
  if (is.null(objs))
    return(NULL)
  dataframes_dims <- Map(
    f = function(name, pkg) {
      attr(name, "package") <- pkg
      tmp <- suppressWarnings(get_env_data(name))
      if (is.data.frame(tmp)) {
        sprintf("%d obs. of  %d variables", nrow(tmp), ncol(tmp))
      }else {
        "Not a data.frame"
      }
    },
    name = objs,
    pkg = if (!is.null(attr(objs, "package"))) {
      attr(objs, "package")
    } else {
      character(1)
    }
  )
  unlist(dataframes_dims)
}
