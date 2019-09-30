# Load the ggplot2 package which provides
# the 'mpg' dataset.
library(ggplot2)

navbarPage('NYC Park Events', #theme = shinytheme("cyborg"),
  tabPanel("NYC Park Events List"),
  
  # Create a new Row in the UI for selectInputs
  fluidRow(
    column(2,
           selectInput("category",
                       "name:",
                       c("All",
                         unique(as.character(total$name))))
    ),
    column(2,
           selectInput("cost_free",
                       "cost_free:",
                       c("All",
                         unique(as.character(total$cost_free))))
    )
  ),
  # Create a new row for the table.
  DT::dataTableOutput("table")
)