#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

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
register_google(key="AIzaSyAZxUv1WdzxUcesZsc3xwgm2Caz2PTEMVc")
key <- "AIzaSyAZxUv1WdzxUcesZsc3xwgm2Caz2PTEMVc"

# fuel project
# import data
altfuel <- read.csv("alt_fuel_stations.csv") 
altfuel <- altfuel[altfuel$Country == "US",] # using only US
altfuel$year <- substr(altfuel$Open.Date,0,4)
# changing geocode for the outlier
#altfuel
altfuel <- altfuel[altfuel$Country == "US",]
fuel_price <- matrix(nrow=1,ncol=7)
fuel_price[1,] <- c(2.19, 1.99, 2, 2.71, 2.91, 2.8, 13)
colnames(fuel_price) <- c("CNG","E85","ELEC","LNG","LPG","BD","HY")
fuel_price <- as.data.frame(fuel_price)
# electric: If electricity costs $0.11 per kilowatt-hour, charging an all-electric vehicle with a 70-mile range (assuming a fully depleted 24 kWh battery) will cost about $2.64 to reach a full charge.

altfuel[which(altfuel$Station.Name == "Greenlots - 182016"),c("Street.Address","State")]
outlier_geo <- geocode("1886 32ND AVE,	CA")
altfuel[33259,c("Latitude","Longitude")] <- c(outlier_geo[[2]],outlier_geo[[1]])
altfuel$State <- as.character(altfuel$State)

anal_data <- altfuel
anal_data$fueltype = as.character(anal_data$Fuel.Type.Code)
anal_data$fueltype[anal_data$fueltype == "ELEC"] <- "Electric"
anal_data$fueltype[anal_data$fueltype == "CNG"] <- 'Compressed Natural Gas'
anal_data$fueltype[anal_data$fueltype == "BD"] <- 'Biodiesel (B20 and above)'
anal_data$fueltype[anal_data$fueltype == "E85"] <- 'Ethanol (E85)'
anal_data$fueltype[anal_data$fueltype == "HY"] <- 'Hydrogen'
anal_data$fueltype[anal_data$fueltype == "LNG"] <- 'Liquefied Natural Gas'
anal_data$fueltype[anal_data$fueltype == "LPG"] <- 'Liquefied Petroleum Gas (Propane)'
anal_data <- as.data.frame(anal_data)

pal <- colorFactor(c("red", "yellow", "orange","green","grey","purple","blue"), domain = unique(altfuel$station_type)) # color palette by fuel type

car_data <- read.csv("light-duty-vehicles.csv")

# choropleth data
states <- geojsonio::geojson_read("station_distribution.geojson", what = "sp")

ui <- 
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


server <- function(input, output) {
    pal <- colorFactor(c("indianred", "yellow", "lightsalmon", "palegreen", "gray74", "lightpink", "cornflowerblue"), domain = unique(altfuel$station_type)) # color palette by fuel type
    
    output$intro_pic <- renderImage({
        filename <- 
            (file.path('intro_pic.jpg'))
        list(src = filename)
    }, deleteFile = FALSE)
    
    output$intro_type <- renderImage({
        filename <- 
            (file.path('icons.jpg'))
        list(src = filename)
    }, deleteFile = FALSE)
    
    output$plot1 <- renderLeaflet({
        if (input$address != "Address"){
            altrows <- which(altfuel$Fuel.Type.Code == input$nav_fuel_type)
            data <- altfuel[altrows,]
            current_location <- geocode(input$address)
            locations <- as.matrix(cbind(data$Longitude, data$Latitude))
            distances <- distHaversine(locations, c(current_location$lon, current_location$lat))
            distances <- as.data.frame(distances)
            data <- altfuel[distances < input$range*1609.34, ]
            leaflet(data) %>%
                addTiles() %>%
                setView(lng = current_location$lon, 
                        lat= current_location$lat, 
                        zoom = 10) %>%
                addMarkers(lng = ~current_location$lon,
                           lat = ~current_location$lat,
                           popup = "Your location") %>%
                addCircles(lng = ~current_location$lon,
                           lat = ~current_location$lat,
                           radius = input$range*1609.34) %>%
                addCircleMarkers(lng = ~Longitude, 
                                 lat = ~Latitude, 
                                 popup = paste(
                                     "Name:", data$Station.Name, "<br>",
                                     "Address:", data$Street.Address,",",
                                     data$City, ",", data$State, "<br>",
                                     "Phone #:", data$Station.Phone, "<br>"
                                 ),
                                 stroke = FALSE,
                                 radius = 5,
                                 fillOpacity = 0.7
                )
        }
        else{
            leaflet() %>%
                addTiles() %>%
                setView(lng = -74, 
                        lat= 40.7, 
                        zoom = 12)
        }
    })
    
    #cholorpleth
    output$heatmap <- renderLeaflet({
        heatrows <- which(altfuel$Fuel.Type.Code == input$heat_fuel_type)
        heatdata <- altfuel[heatrows,]
        if(input$heat_fuel_type == "All"){
            leaflet(altfuel) %>%
                addProviderTiles("CartoDB.Positron") %>%
                addHeatmap(blur = 20, max = 0.05, radius = 15)
        }
        else{
            leaflet(heatdata) %>%
                addProviderTiles("CartoDB.Positron") %>%
                addHeatmap(blur = 20, max = 0.05, radius = 15)
        }
    })
    
    output$calc_result <- renderText({
        fuel_price[1,input$fuel_price] * input$tank
    })
    output$fuel_table1 <- renderImage({
        filename <- normalizePath(file.path('table2.png'))
        list(src = filename, width = "300px", height="300px")
    }, deleteFile = FALSE)
    output$fuel_table2 <- renderImage({
        filename <- normalizePath(file.path('table3.png'))
        list(src = filename, width = "300px", height="300px")
    }, deleteFile = FALSE)
    output$fuel_description <- renderText({
        "CNG(per GGE), LNG(per DGE), E85,BD: per Gallon, Hydrogen(per Kg)"
    })
    output$nav <- renderGoogle_map({
        if (input$nav_start == "Address"){
            default_map <- c(geocode("new york, ny")[[2]],geocode("new york, ny")[[1]])
            google_map(key=key, location = default_map)
        } 
        else{
            df <- google_directions(origin = input$nav_start,
                                    destination = input$nav_end,
                                    key = key,
                                    mode = "driving",
                                    simplify = TRUE)
            pl <- df$routes$overview_polyline$points
            pl <- direction_polyline(df)
            polyline <- pl[1]
            df <- decode_pl(polyline)
            df <- data.frame(polyline = pl)
            google_map(key = key) %>%
                add_polylines(data = df, polyline = "polyline", stroke_weight = 9)
        }
    })
    output$nav_distance <- renderText({
        # calculating distance
        time_dis <- gmapsdistance(origin= paste(geocode(input$nav_start)[[2]],"+", 
                                                geocode(input$nav_start)[[1]],sep = ""), 
                                  destination= paste(geocode(input$nav_end)[[2]],"+",
                                                     geocode(input$nav_end)[[1]],sep = ""),
                                  departure = "now",
                                  key = "AIzaSyAZxUv1WdzxUcesZsc3xwgm2Caz2PTEMVc",
                                  mode = "driving")
        navigation_distance <- time_dis$Distance #meters
        navigation_time <- time_dis$Time #seconds
        navigation_distance * 0.000621371
    })
    output$nav_time <- renderText({
        # calculating time
        time_dis <- gmapsdistance(origin= paste(geocode(input$nav_start)[[2]],"+", 
                                                geocode(input$nav_start)[[1]],sep = ""), 
                                  destination= paste(geocode(input$nav_end)[[2]],"+",
                                                     geocode(input$nav_end)[[1]],sep = ""),
                                  departure = "now",
                                  key = "AIzaSyAZxUv1WdzxUcesZsc3xwgm2Caz2PTEMVc",
                                  mode = "driving")
        navigation_time <- time_dis$Time #seconds
        td <- seconds_to_period(navigation_time)
        sprintf('%03d %02d:%02d:%02d', day(td), td@hour, minute(td), second(td))
    })
    output$analytics <- renderPlotly({
        if(input$bar_state != "All"){
            count_by_fuel <- altfuel%>%
                filter(State == input$bar_state) %>%
                group_by(Fuel.Type.Code) %>%
                tally()
        }
        else{
            count_by_fuel <- altfuel%>%
                group_by(Fuel.Type.Code) %>%
                tally()
        }
        
        plot_ly(
            x = count_by_fuel$Fuel.Type.Code,
            y = count_by_fuel$n,
            name = "Counts",
            type = "bar",
        ) %>%
            layout(title = "Number of stations by fuel type")
    })
    
    output$animate <- renderLeaflet({
        animatedata <- subset(altfuel, year == 1953)
        if (input$heat_years > 1953){
            animatedata <- subset(altfuel, year %in% c(1953:input$heat_years))
        }
        leaflet(animatedata) %>%
            addProviderTiles("CartoDB.Positron") %>%
            addCircleMarkers(lng = ~Longitude, 
                             lat = ~Latitude,
                             stroke = FALSE,
                             radius = 5,
                             fillOpacity = 0.7,
                             color = ~pal(Fuel.Type.Code)) %>%
            addLegend("bottomright", pal = pal, values = ~Fuel.Type.Code,
                      title = "Fuel type",
                      opacity = 1)
    })
    output$directory <- renderDataTable({
        shortinfo <- altfuel[,c('Station.Name','Street.Address','City','State','ZIP','Station.Phone','Owner.Type.Code','Access.Detail.Code')]
        shortinfo
    })
    output$timeline <- renderPlotly({
        timedata_temp <- altfuel[,c('Fuel.Type.Code','year')]
        timedata <- altfuel%>%
            group_by(year, Fuel.Type.Code) %>%
            tally()
    })
    output$gasoline_calc <- renderText({
        #distance
        dis <- gmapsdistance(origin= paste(geocode(input$start_point)[[2]],"+", 
                                           geocode(input$start_point)[[1]],sep = ""), 
                             destination= paste(geocode(input$end_point)[[2]],"+",
                                                geocode(input$end_point)[[1]],sep = ""),
                             departure = "now",
                             key = "AIzaSyAZxUv1WdzxUcesZsc3xwgm2Caz2PTEMVc",
                             mode = "driving")
        distance_val <- dis$Distance #meters
        distance_time <- dis$Time #seconds
        #gas price
        gas_price <- 3
        #car data
        
        gas_data <- car_data %>%
            filter(Manufacturer  == input$car_brand) %>%
            filter(Model.Year  == input$car_year) %>%
            filter(Model  == input$model_selection)
        
        # gas_data <- car_data %>%
        #   filter(Manufacturer  == input$car_brand) %>%
        #   filter(Model.Year  == input$car_year) %>%
        #   filter(Model  == input$model_selection)
        gas_data <- gas_data[,c("Conventional.Fuel.Economy.City", "Conventional.Fuel.Economy.Highway")]
        distance_val * 0.000621371 / gas_data[,1] * gas_price
    })
    
    output$piechart <- renderPlotly({
        anal_data %>%
            group_by(fueltype) %>%
            summarise(count= n()) %>%
            plot_ly(labels=~fueltype, values = ~count, type = 'pie') %>%
            layout(title = "Count of Alternative Fuel Stations by Fuel Type",
                   xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                   yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
        
    })
    
    output$access <- renderPlotly({
        access<- anal_data %>%
            group_by(Access.Code, fueltype) %>%
            summarise(count = n()) 
        
        access<- access %>%
            group_by(fueltype) %>%
            mutate(countT=sum(count)) %>%
            group_by(Access.Code, add = TRUE) %>%
            mutate(per = round(100*count/countT,1)) %>%
            subset(select = -c(count, countT))
        
        
        #from long to wide
        access_wide <- spread(access,Access.Code,per)
        
        top_labels<- c("Public", "Private")
        x1<- access_wide$public
        x2 <- access_wide$private
        access_wide %>%
            plot_ly(x = ~private, y = ~fueltype, type = 'bar', orientation = 'h',
                    marker = list(color = 'rgb(34,139,34)',
                                  line = list(color = 'rgb(107,142,35)', width = 1))) %>%
            add_trace(x = ~public, y = ~fueltype, type = 'bar', orientation = 'h', marker = list(color = 'rgb(143,188,143)')) %>%
            layout(xaxis = list(title = "",
                                showgrid = FALSE,
                                showline = FALSE,
                                showticklabels = FALSE,
                                zeroline = FALSE,
                                domain = c(0.15, 1)),
                   yaxis = list(title = "",
                                showgrid = FALSE,
                                showline = FALSE,
                                showticklabels = FALSE,
                                zeroline = FALSE),
                   barmode = 'stack',
                   paper_bgcolor = 'rgb(248, 248, 255)', plot_bgcolor = 'rgb(248, 248, 255)',
                   margin = list(l = 120, r = 10, t = 140, b = 80),
                   showlegend = FALSE,
                   title = "Access by fuel type") %>%
            add_annotations(xref = 'paper', yref = 'y', x = 0.14, y = access_wide$fueltype,
                            xanchor = 'right',
                            text = access_wide$fueltype,
                            font = list(family = 'Arial', size = 12,
                                        color = 'rgb(67, 67, 67)'),
                            showarrow = FALSE, align = 'right') %>%
            add_annotations(xref = 'x', yref = 'paper',
                            x = c(31.7/ 2, 31.7+68.3/ 2),
                            y = 1.15,
                            text = top_labels,
                            font = list(family = 'Arial', size = 12,
                                        color = 'rgb(67, 67, 67)'),
                            showarrow = FALSE) %>%
            add_annotations(xref = 'x', yref = 'y',
                            x = x2/ 2, y = access_wide$fueltype,
                            text = paste(x2, '%'),
                            font = list(family = 'Arial', size = 12,
                                        color = 'rgb(248, 248, 255)'),
                            showarrow = FALSE) %>%
            add_annotations(xref = 'x', yref = 'y',
                            x = x2 + x1 / 2, y = access_wide$fueltype,
                            text = paste(x1, '%'),
                            font = list(family = 'Arial', size = 12,
                                        color = 'rgb(248, 248, 255)'),
                            showarrow = FALSE)
    })
    output$model_select <- renderText({
        temp <- car_data %>%
            filter(Manufacturer == input$car_brand) %>%
            select(Model)
        unique(temp)
    })
    
    output$choro <- renderLeaflet({
        bins <- c(0, 100, 150, 200, 300, 400, 500, 1000, 1500,2000,Inf)
        choro_pal <- colorBin("Greens", domain = density, bins = bins)
        labels <- sprintf(
            "<strong>%s</strong><br/>%g stations",
            states$name, states$density
        ) %>% lapply(htmltools::HTML)
        
        leaflet(states) %>%
            setView(-96, 37.8, 4) %>%
            addProviderTiles("MapBox", options = providerTileOptions(
                id = "mapbox.light",
                accessToken = Sys.getenv('MAPBOX_ACCESS_TOKEN'))) %>%
            addPolygons(
                fillColor = ~choro_pal(density),
                weight = 2,
                opacity = 1,
                color = "white",
                dashArray = "3",
                fillOpacity = 0.7,
                highlight = highlightOptions(
                    weight = 5,
                    color = "#666",
                    dashArray = "",
                    fillOpacity = 0.7,
                    bringToFront = TRUE),
                label = labels,
                labelOptions = labelOptions(
                    style = list("font-weight" = "normal", padding = "3px 8px"),
                    textsize = "15px",
                    direction = "auto")) %>%
            addLegend(pal = choro_pal, values = ~density, opacity = 0.7, title = NULL,
                      position = "bottomright")
    })
    output$top_states <- renderPlotly({
        top10_state <-anal_data %>%
            group_by(State) %>%
            summarise(count=n())%>%
            arrange(desc(count))%>%
            head(n=10)
        top10_state$State = as.character(top10_state$State)
        top10_state$State <- factor(top10_state$State, levels = top10_state[['State']])
        top10_state %>%
            plot_ly(x = ~State, y = ~count, type = 'bar',
                    marker = list(color = c('rgb(143,188,143)',
                                            'rgba(204,204,204,1)','rgba(204,204,204,1)', 'rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)', 'rgba(204,204,204,1)', 'rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)','rgba(204,204,204,1)','rgba(204,204,204,1)'))) %>%
            layout(title = "Top 10 States with the most number of alternative fuel stations",
                   xaxis = list(title = "State"),
                   yaxis = list(title = "Count of Stations"))
    })
    
    output$top_city <- renderPlotly({
        top10_state <-anal_data %>%
            group_by(State) %>%
            summarise(count=n())%>%
            arrange(desc(count))%>%
            head(n=10)
        
        top10_state$State = as.character(top10_state$State)
        top10_state$State <- factor(top10_state$State, levels = top10_state[['State']])
        top10_state %>%
            plot_ly(x = ~State, y = ~count, type = 'bar',
                    marker = list(color = c('rgb(143,188,143)',
                                            'rgba(204,204,204,1)','rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)', 'rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)','rgba(204,204,204,1)',
                                            'rgba(204,204,204,1)'))) %>%
            layout(title = "Top 10 States with the most number of alternative fuel stations",
                   xaxis = list(title = "State"),
                   yaxis = list(title = "Count of Stations"))
    })
    output$timeseries <- renderPlotly({
        station_date <- altfuel %>% select(Fuel.Type.Code, Date.Last.Confirmed, Open.Date)
        fillNA <- function(x, y) {
            if (is.na(x)) {y} else {x}
        }
        station_date$`Year` <- format(as.Date(apply(station_date[,c("Open.Date","Date.Last.Confirmed")],1,function(x) fillNA(x[1],x[2]))),"%Y")
        # Due to the existance of outliers (BD)in last few year, thus a natural log is used to make the plot more readable.
        countGB <- station_date %>% 
            group_by(Fuel.Type.Code, Year) %>% 
            summarise(Count = log(n()))
        plot_ly(countGB, x=~Year, y=~Count, color=~Fuel.Type.Code) %>% 
            add_lines() %>%
            layout(title= "Number of stations by time", yaxis = list(title="Log(Counts)"))
    })
}
# Run the application 
shinyApp(ui = ui, server = server)
