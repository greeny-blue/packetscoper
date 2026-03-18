library(dplyr)
library(stringr)
library(shiny)
library(plotly)
library(bslib)

#--- for sorting ips numerically (load this as a library in the future)
sort_ip <- function(ip_strings, desc = F){
  
  out <- lapply(ip_strings, str_split, "\\.") %>%
    unlist() %>% 
    as.numeric() %>%
    matrix(ncol = 4, byrow = T) %>% 
    data.frame()
  
  if(desc){
    out <- out %>% arrange(desc(X1), desc(X2), desc(X3), desc(X4))
  } else {
    out <- out %>% arrange(X1, X2, X3, X4)
  }
  
  apply(out, 1, paste, collapse = ".")
  
}

#--- user interface
pcap_ui <- fluidPage(
  theme = bs_theme(),
  titlePanel("PacketScopeR"),
  fluidRow(
    column(12,
           tabsetPanel(
             tabPanel(
               "Raw data",
               fluidRow(
                 column(12,
                        #--- controls
                        wellPanel(
                          fluidRow(
                            column(6,
                                   fileInput("file_upload", "Load parsed .pcap (.csv)")
                            ),
                            column(3,
                                   selectInput("select_data_type", "Select data", choices = "", selected = "None")
                            ),
                            column(3,
                                   radioButtons("radio_data_sort", "Sort by", choices = c("Variable", "Count"), selected = "Variable", inline = T)
                            )
                          ),
                          fluidRow(
                            column(3,
                                   textInput("text_local_network", "Local network (e.g., 192.168.1.X)", value = "192.168.1.X") # or use CIDR
                            ),
                            column(3,
                                   radioButtons("radio_network_filter", "Network", choices = c("Internal only", "External <-> Internal", "All"), selected = "All", inline = T)
                            ),
                            column(6,
                                   checkboxInput("dark_mode", "Dark mode", value = T)
                            )
                          )
                        )
                 )
               ),
               #--- outputs
               fluidRow(
                 column(6,
                        DT::DTOutput("table_of_data")
                 ),
                 column(6, 
                        plotlyOutput("plot_of_data", height = 700)
                 )
               )
               
               
             )
           )      
    )
    
  )
)

#--- server
pcap_server <- function(input, output, session){
  
  #--- light/dark mode
  observe({
    if (input$dark_mode) {
      session$setCurrentTheme(
        bs_theme(bg = "#222222", fg = "#FFFFFF", primary = "#4CAF50")
      )
    } else {
      session$setCurrentTheme(
        bs_theme(bg = "#FFFFFF", fg = "#000000", primary = "#007BFF")
      )
    }
  })
  
  #--- distinguish internal only from traffic coming in/going out to the internet
  internal_ip <- reactive({
    iip <- tolower(input$text_local_network) %>% str_split("\\.") %>% unlist()
    iip <- iip[iip != "x"]
    paste0(paste0(iip, collapse = "\\."), "\\.")
  })
  
  is_internal <- function(ip) {
    str_detect(ip, internal_ip())
  }
  
  #--- data upload and manipulation
  pcap_file <- reactive({
    if(is.null(input$file_upload)){
      data.frame()
    } else {
      out <- as.data.frame(read.csv(input$file_upload$datapath)) %>%
        mutate(
          src_internal = is_internal(src_ip),
          dst_internal = is_internal(dst_ip),
          traffic_class = case_when(
            src_internal & dst_internal ~ "Internal <-> Internal",
            src_internal | dst_internal ~ "External <-> Internal",
            TRUE ~ "External"
          )
        )
      if(input$radio_network_filter == "Internal only"){
        out %>% filter(traffic_class == "Internal <-> Internal")
      } else if (input$radio_network_filter == "External <-> Internal"){
        out %>% filter(traffic_class == "External <-> Internal")
      } else {
        out
      }
    }
  })
  
  #--- for populating column viewer with isolate to prevent widget resets
  observe({
    current <- isolate(input$select_data_type)
    choices <- names(pcap_file())
    
    selected <- if (!is.null(current) && current %in% choices) {
      current
    } else {
      choices[1]
    }
    
    updateSelectInput(
      session,
      "select_data_type",
      choices = choices,
      selected = selected
    )
  })
  
  #--- table output
  output$table_of_data <- DT::renderDataTable({
    
    req(input$file_upload)
    pcap_file()
    
  })
  
  #--- plotly output for counting column instances
  output$plot_of_data <- renderPlotly({
    
    if(input$select_data_type == ""){
      p <- plot_ly()
    } else {
      df_summary <- pcap_file()[[input$select_data_type]] %>%
        table() %>%
        data.frame() %>%
        setNames(c("Variable", "Count")) %>%
        filter(Variable != "")
      
      if(input$radio_data_sort == "Variable"){
        if(str_detect(input$select_data_type, "_ip")){
          ordered_ips <- sort_ip(df_summary$Variable)
          df_summary <- df_summary %>%
            arrange(match(Variable, ordered_ips))
        } else {
          df_summary <- df_summary %>%
            arrange(.data[[input$radio_data_sort]])
        }
      } else if(input$radio_data_sort == "Count"){
        df_summary <- df_summary %>% 
          arrange(Count)
      }
      df_summary$Variable <- factor(df_summary$Variable, levels = df_summary$Variable)
      
      p <- plot_ly(
        df_summary,
        y = ~Variable,
        x = ~Count,
        type = "bar",
        orientation = "h",
        hovertemplate = paste0(
          input$select_data_type, ": %{y}<br>",
          "Count: %{x}<extra></extra>"
        )      
      ) %>%
        layout(yaxis = list(title = "", showgrid = FALSE))
    }
    
    #--- dark mode control for plotly
    if(input$dark_mode){
      p <- p %>% layout(
        paper_bgcolor = "#222222",
        plot_bgcolor  = "#222222",
        font = list(color = "#FFFFFF"),
        xaxis = list(gridcolor = "#444444"),
        yaxis = list(gridcolor = "#444444")
      )
    } else {
      p <- p %>% layout(
        paper_bgcolor = "#FFFFFF",
        plot_bgcolor  = "#FFFFFF",
        font = list(color = "#000000"),
        xaxis = list(gridcolor = "#DDDDDD"),
        yaxis = list(gridcolor = "#DDDDDD")
      )
    }
    
    p
    
  })
}

#--- run app
shinyApp(pcap_ui, pcap_server)

