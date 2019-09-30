library(ggplot2)

d1 <- read.csv("C:/Users/yg916/Documents/GitHub/fall2019-proj2--sec1-grp8/data/ParkData/NYC_Parks_Events_Listing___Event_Categories.csv", header=TRUE,
               sep=",")
d2 <- read.csv("C:/Users/yg916/Documents/GitHub/fall2019-proj2--sec1-grp8/data/ParkData/NYC_Parks_Events_Listing___Event_Listing.csv", header=TRUE,
               sep=",")
total <- merge(d1,d2,by="ï..event_id")

function(input, output) {
  
  # Filter data based on selections
  output$table <- DT::renderDataTable(DT::datatable({
    data <- total
    if (input$category != "All") {
      data <- data[data$name == input$category,]
    }
    if (input$cost_free != "All") {
      data <- data[data$cost_free == input$cost_free,]
    }
    data
  }))
  
}