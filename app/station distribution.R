library('leaflet')
library('sf')
library( 'geojsonio' )
library('geojsonlint')
setwd('C:/Users/rui/Desktop/cu/spring2019/database/fall2019-proj2--sec1-grp8/app')

states <- geojsonio::geojson_read("../data/station_distribution.geojson", what = "sp")
bins <- c(0, 100, 150, 200, 300, 400, 500, 1000, 1500,2000,Inf)
pal <- colorBin("YlOrRd", domain = density, bins = bins)



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
    fillColor = ~pal(density),
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
  addLegend(pal = pal, values = ~density, opacity = 0.7, title = NULL,
            position = "bottomright")