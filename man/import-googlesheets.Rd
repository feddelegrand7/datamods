% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/import-googlesheets.R
\name{import-googlesheets}
\alias{import-googlesheets}
\alias{import_googlesheets_ui}
\alias{import_googlesheets_server}
\title{Import data with a googlesheet link}
\usage{
import_googlesheets_ui(id)

import_googlesheets_server(
  id,
  trigger_return = c("button", "change"),
  return_class = c("data.frame", "data.table", "tbl_df")
)
}
\arguments{
\item{id}{Module's ID}

\item{trigger_return}{When to update selected data:
\code{"button"} (when user click on button) or
\code{"change"} (each time user select a dataset in the list).}

\item{return_class}{Class of returned data: \code{data.frame}, \code{data.table} or \code{tbl_df} (tibble).}
}
\value{
\itemize{
\item UI: HTML tags that can be included in shiny's UI
\item Server: a \code{list} with one slot:
\itemize{
\item \strong{data}: a \code{reactive} function returning the selected \code{data.frame}.
}
}
}
\description{
Let user paste link to a Google sheet then import the data.
}
\examples{

library(shiny)
library(datamods)

ui <- fluidPage(
  tags$h3("Import data with googlesheets"),
  fluidRow(
    column(
      width = 4,
      import_googlesheets_ui("myid")
    ),
    column(
      width = 8,
      tags$b("Imported data:"),
      verbatimTextOutput(outputId = "result")
    )
  )
)

server <- function(input, output, session) {
  
  imported <- import_googlesheets_server("myid")
  
  output$result <- renderPrint({
    imported$data()
  })
  
}

if (interactive())
  shinyApp(ui, server)
}
