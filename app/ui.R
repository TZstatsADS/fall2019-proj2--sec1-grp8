library(dtplyr)
library(dplyr)
library(DT)
library(lubridate)
library(shiny)
library(choroplethr)
library(choroplethrZip)
library(ggplot2)
library(ggmap)
library(readr)
library(plyr)
library(tmap)
library(sf)
library(leaflet)
library(raster)
library(spData)
library(shinydashboard)
library(shinythemes)
library(leaflet.extras)
library(magrittr)
library(gmapsdistance)
library(plotly)
library(googleway)
library(mapview)
library(shinyWidgets)
library(googleVis)
library(geosphere)
library(tidyr)
library(geojsonio)
library(geojsonlint)


  dashboardPage(skin = "green",
                dashboardHeader(title = "Alternative Fuel Guide"),
                dashboardSidebar(
                  sidebarMenu(
                    menuItem("Introduction", tabName = "intro", icon = icon("fas fa-gas-pump")),
                    menuItem("Map", tabName = "navigation", icon = icon("map")),
                    menuItem("Calculate", icon = icon("calculator"), tabName = "calculate"),
                    menuItem("Analytics", icon = icon("fas fa-chart-bar"), tabName = "analytics"),
                    menuItem("Directory", icon = icon("book"), tabName = "directory"),
                    menuItem("Contact Us", icon = icon("question"), tabName = "contacts")
                  )
                ),
                dashboardBody(
                  tabItems(
                    tabItem(
                      tabName = "intro",
                      fluidRow(
                        box(
                          title = "Overview",
                          status="primary",
                          solidHeader = TRUE,
                          background = "green",
                          width="auto",
                          plotOutput(outputId="intro_pic",width="auto",inline=TRUE),
                          p(""),
                          p(""),
                          h4("Alternative fuels are any materials that can be used as fuels, 
            other than conventional fuels. Common alternative fuels include 
            Compressed Natural Gas, Electric, Hydrogen, and Liquefied Natural Gas."),
                          plotOutput(outputId="intro_type",width="80%",inline=TRUE)
                        )
                      ),
                      fluidRow(
                        box(
                          width=6,
                          h4("Helps eco-friendly drivers find nearby alternative fuel 
          stations and calculate the estimated price of alternative fuels they 
          need to get to their destinations."),
                          infoBox("Types", 7, icon = icon("calculator"),fill = TRUE, width = "auto")
                        ),
                        box(
                          width=6,
                          h4("Contains an analytics report that shows some preliminary
          data analysis results to help people learn more about how alternative fuel is adapted in the U.S."),
                          infoBox("Analytics", 10, icon = icon("fas fa-chart-bar"),fill = TRUE, width = "auto")
                        )
                      )
                    ),
                    tabItem(
                      tabName= "navigation",
                      navbarPage(
                        "Tools :",
                        tabPanel(
                          "Nearby stations",
                          leafletOutput("plot1"),
                          fluidRow(
                            box(selectInput(inputId = "nav_fuel_type",
                                            label= h3("Fuel type"),
                                            choices = unique(altfuel$Fuel.Type.Code)),
                                textInput(h3("Currnet Location"), inputId = "address", value = "Address")),
                            box(sliderInput(inputId = "range", "Radius Range:",
                                            min = 0, max = 50, value = 6))
                          )
                        ),
                        tabPanel(
                          "Navigation",
                          google_mapOutput("nav"),
                          hr(),
                          fluidRow(
                            box(
                              textInput("Starting address",inputId = "nav_start", value = "Address"),
                              textInput("Ending address",inputId = "nav_end")
                            ),
                            box(
                              h4("Estimated distance and Time"),
                              h5("Distance (in miles)"),
                              textOutput(outputId = "nav_distance"),
                              h5("Estimated Time (dd:hh:mm:ss)"),
                              textOutput(outputId = "nav_time")
                            )
                          )
                        )
                      )
                    ),
                    tabItem(
                      tabName = "calculate",
                      navbarPage(
                        "Calculators:",
                        tabPanel(
                          "Alternative fuels",
                          fluidRow(
                            box(
                              h4("Average price"), height = 350,
                              plotOutput(outputId = "fuel_table1", width = "50%", height="200px")),
                            box(
                              h4("Average price by EEF"), height = 350,
                              plotOutput(outputId = "fuel_table2", width = "50%", height="200px")),
                            box(
                              numericInput(h4("Tank size"),value = 1, inputId = "tank"),
                              textOutput("fuel_description"),
                              selectInput(inputId = "fuel_price",
                                          label= h4("Fuel type"),
                                          choices = unique(altfuel$Fuel.Type.Code)
                              )
                            ),
                            box(
                              h3("Estimated Cost($):"),
                              textOutput("calc_result"))
                          )
                        ),
                        tabPanel(
                          "Gasoline",
                          fluidPage(
                            fluidRow(
                              textInput(inputId = "start_point","Start"),
                              textInput(inputId = "end_point","Destination")
                            ),
                            fluidRow(
                              selectInput(inputId = "car_brand","Manufacturer",
                                          choices = unique(car_data$Manufacturer)),
                              selectInput(inputId = "car_year","Year",
                                          choices = unique(car_data$Model.Year)),
                              selectizeInput(inputId = 'model_selection', 
                                             label = "Model", choices = unique(car_data$Model),
                                             selected = NULL,
                                             options = list(maxOptions=10, create = TRUE),
                              ),
                              box(
                                h3("Estimated cost($):"),
                                textOutput("gasoline_calc")
                              )
                            )
                          )
                        )
                      )
                    ),
                    
                    tabItem(tabName = "analytics",
                            navbarPage(
                              "Analytics:",
                              tabPanel(
                                "Maps",
                                tabsetPanel(
                                  tabPanel(
                                    "Heatmap",
                                    fluidRow(
                                      leafletOutput("heatmap"),
                                      selectInput(inputId = "heat_fuel_type",
                                                  label= "Fuel type",
                                                  choices = c("All",as.character(unique(altfuel$Fuel.Type.Code))))
                                    )
                                  ),
                                  tabPanel(
                                    "Choropleth",
                                    leafletOutput("choro")
                                  ),
                                  tabPanel(
                                    "Animation",
                                    fluidRow(
                                      leafletOutput("animate"),
                                      sliderInput(inputId = "heat_years",
                                                  label="Years",
                                                  min = 1953, max = 2019, value=2000,
                                                  animate=animationOptions(interval = 500))
                                    )
                                  )            
                                )
                              ),
                              tabPanel(
                                "Charts",
                                tabsetPanel(
                                  tabPanel(
                                    "Bar chart",
                                    fluidRow(
                                      plotlyOutput("analytics"),
                                      selectizeInput(h3("State:"), inputId ="bar_state", 
                                                     choices = c("All",unique(altfuel$State)))
                                    )
                                  ),
                                  tabPanel(
                                    "Time series",
                                    fluidRow(
                                      box(plotlyOutput("timeseries"), width = "auto")
                                    )
                                  ),
                                  tabPanel(
                                    "Pie chart",
                                    fluidRow(
                                      box(plotlyOutput("piechart"), width = "auto")
                                    )
                                  ),
                                  tabPanel(
                                    "Access type",
                                    fluidRow(
                                      box(plotlyOutput("access"), width = "auto")
                                    )
                                  ),
                                  tabPanel(
                                    "Top states",
                                    fluidRow(
                                      box(plotlyOutput("top_states"), width = "auto")
                                    )
                                  ),
                                  tabPanel(
                                    "Top Cities",
                                    fluidRow(
                                      box(plotlyOutput("top_city"), width = "auto")
                                    )
                                  )
                                )
                              )
                            )
                    ),
                    tabItem(
                      tabName = "directory",
                      fluidRow(
                        h3("Directory"),
                        dataTableOutput("directory")
                      )
                    ),
                    tabItem(
                      tabName = "contacts",
                      fluidRow(
                        column(width = 12,
                               h2("If you have any questions, please contact:")),
                        box(
                          h4("Daniel Lee - dl3250@columbia.edu"),
                          h4("Rui Cao - "),
                          h4("Suzy - "),
                          h4("Evelyn - "),
                          h4("Yuting - ")
                        )
                      )
                    )
                  )
                )
  )
```