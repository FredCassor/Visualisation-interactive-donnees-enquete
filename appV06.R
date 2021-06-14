################################################################################
#                                                                              #
#       Application de visualisation interactive de donnees d'enquetes         #
#                                                                              #
#       Exemple : confiance dans le Premier Ministre en France                 #
#                 entre 2009 et 2018                                           #
#                                                                              #
#       Source : enquetes CEVIPOF                                              #
#                                                                              #
#       Auteurs : Frederik CASSOR, Nicolas SORMANI (2021)                      #
#                                                                              #
################################################################################


# verifier que le codage est utf-8 dans le menu de R :
# File/Reopen with encoding/UTF-8/Set as default encoding for source files


# telecharger la librairie de creation d'applications Shiny
library(shiny)
# telecharger la librairie de datascience Tidyverse
library(tidyverse)
# telecharger les librairies d'animation d'images
library(gganimate)
library(gifski) # necessaire pour assurer le bon fonctionnement de animate()
# librairie pour personnaliser la police de font
library(extrafont)
# librairie utile au telechargement d'une image au format Gif
library(animation)
# librairie de representation interactive de donnees
library(plotly)


#------------------------------------------------------------------------------#
# Importer les donnees au format Excel                                         #
#------------------------------------------------------------------------------#

library(readxl)      # import Excel
library(openxlsx)    # export Excel

App_Data0 <- read_excel("App_Data.xls")
App_Data1 <- App_Data0 # sauvegarde intermediaire de la base initiale

# preparer la table telechargeable par l'utilisateur
App_Data0[, "Year"] <- c(2009:2018)

# mettre en forme la base de travail sous-jacente a l'application
App_Data1 <- App_Data1 %>%
                  # creer une colonne contenant la variable vague
                  # comme nombre compris entre 1 et le nombre de lignes
                  # du fichier initial
                  mutate(vague = seq(1:nrow(App_Data1))) %>%
                  # "pivot data from wide to long" : ranger les donnees de %
                  # du tableau d'origine en une seule colonne
                  pivot_longer(contains("confident"), 
                               names_to = "categorie",
                               values_to = "percent") %>%
                  # calculer l'arrondi des pourcentages originels
                  mutate(lbl = round(100*percent, 1))

# creer les modalites de reponses possibles comme etiquettes du facteur categorie
# de la nouvelle base de donnees
App_Data1$categorie <- factor(App_Data1$categorie,
                              levels = c("Totally confident",
                                         "Somewhat confident",
                                         "Somewhat not confident",
                                         "Not confident at all"))

# creer les annees des vagues d'enquetes, comme nouveaux codes du facteur vague
# de la nouvelle base de donnees
App_Data1$year <- App_Data1$vague %>%
    factor %>%
    fct_recode(
        "2009" = "1",
        "2010" = "2",
        "2011" = "3",
        "2012" = "4",
        "2013" = "5",
        "2014" = "6",
        "2015" = "7",
        "2016" = "8",
        "2017" = "9",
        "2018" = "10"
    )

# definir le format francais des %
french_percent <- scales::label_percent(
    accuracy = 1,
    decimal.mark = ",",
    suffix = " %"
)

# autre fonction pour definir le format francais des %
pourcentage <- function(nombre, ...){
  txt <- paste(prettyNum(nombre*100, big.mark=" ", decimal.mark = ",", ...),"%")
  return(ifelse(nombre == 0,"",txt))
}

# definir le vecteur des couleurs utiles aux barres des graphiques simples
cols = c("#00FF00", "#CCFFCC", "#FFCC33", "#CC0033")
# definir le vecteur des couleurs utiles aux 10 graphiques simples animes en tab6
COLS = c(cols, cols, cols, cols, cols, cols, cols, cols, cols, cols)


#------------------------------------------------------------------------------#
# Bloc de definition de l'interface avec l'utilisateur (UI)                    #
#------------------------------------------------------------------------------#

ui <- fluidPage(
    
    # creer la structure par panneaux individuels
    tabsetPanel(
        
        # creer le premier panneau : decrire l'application
        tabPanel("Menu",
                 
                 # creer l'espace pour accueillir le titre de la page
                 titlePanel("FRANCE - Confidence in the Prime Minister"),

                 # ligne unique de la page d'accueil, avec logo en fond d'ecran
                 fluidRow(style = "background-image: url(https://www.sciencespo.fr/cevipof/sites/sciencespo.fr.cevipof/files/barologo276bec8.jpg?1609832615); background-size: contain; background-repeat: no-repeat;",
                          
                 # creer l'espace pour accueillir la description des onglets
                 mainPanel(
                   
                     # sauts de ligne
                     p(br(),
                       br(),
                     ),
                     
                     # phrase introductive
                     p(strong("This web application aims at interactively
                     representing data"),
                       br(),
                       strong("from CEVIPOF (Sciences Po Paris) concerning
                              citizens' confidence"),
                       br(),
                       strong("in the Prime Minister from 2009 to 2018.")
                     ),
                     
                     # saut de ligne
                     p(br()),
                     
                     # description des panneaux
                     p("The application is organized as follow:",
                       br(),
                       br(),
                       "- Tab1: all confidence degrees over the whole period
                       of time;",
                       br(),
                       br(),
                       "- Tab2: confidence degrees (to select) over the whole
                       period of time;",
                       br(),
                       br(),
                       # "- Tab3: all confidence degrees over a period of time
                       # (to select);",
                       # br(),
                       # br(),
                       "- Tab3bis: all confidence degrees over a period of time
                       (to select) with another interactive ploting method;",
                       br(),
                       br(),
                       "- Tab4: all confidence degrees per year (to select);",
                       br(),
                       br(),
                       "- Tab5: dynamic display of all confidence degrees per
                       year;",
                       br(),
                       br(),
                       "- Tab6: one chart per year on all confidence degrees ;
                       then, the charts are displayed dynamically over the whole
                       period of time."
                       ),
                   
                     # saut de ligne
                     p(br()),
                     
                     # creer l'espace pour accueillir le bouton de
                     # telechargement de la base de donnees totale
                     downloadButton(outputId = "DownloadData",
                                    label = "Download data in Excel"),
                     
                     # sauts de ligne
                     p(br())
                ),
              ),
                
                # creer l'espace pour accueillir les references
                fluidRow(column(width = 6,
                             em("Data from CEVIPOF - CEVIPOF (2021)
                                - F. Cassor, N. Sormani.")
                             )
                      )
        ),
        
        tabPanel("Tab1",
                  
                  # creer l'espace pour accueillir le titre de la page
                  titlePanel("FRANCE - Confidence in the Prime Minister"),
                  
                 # creer l'espace pour accueillir l'histogramme
                 mainPanel(
                   tabsetPanel(
                     tabPanel("Figure",
                              plotOutput("confPlot1"),
                              
                              # creer l'espace pour accueillir le bouton de telechargement
                              # du graphique
                              fluidRow(column(width = 6,
                                              downloadButton(outputId = "DownloadChart1",
                                                             label = "Download chart")
                              )
                              )
                              
                     ),
                     
                     tabPanel("Table",
                              p(em("(% row)"),
                                br()),
                              tableOutput("table")
                     )
                   )
                 ),
                 
                 
                 # saut de ligne
                 p(br()),
                 
                 # creer l'espace pour accueillir les references
                 fluidRow(column(width = 6,
                                 em("Data from CEVIPOF - CEVIPOF (2021)
                                     - F. Cassor, N. Sormani.")
                 )
                 )
        ),

        tabPanel("Tab2",
                 
                 # creer l'espace pour accueillir le titre de l'application
                 titlePanel("FRANCE - Confidence in the Prime Minister"),
               
                 # sauts de ligne
                 p(br(),
                   br(),
                 ),
                 
                 # creer l'espace pour accueillir les objets a visualiser
                 sidebarLayout(  
                     
                     # creer l'espace pour accueillir le menu deroulant
                     # des variables a choisir de representer
                     sidebarPanel(
                         selectInput(inputId = "confdeg",
                                     label = "Confidence degree:", 
                                     choices = levels(App_Data1$categorie)),
                         
                         # creer l'espace pour accueillir le bouton de
                         # telechargement du graphique
                         fluidRow(
                             downloadButton(outputId = "DownloadChart2",
                                            label = "Download chart")
                         )
                     ),
                     
                     # creer l'espace pour accueillir l'histogramme
                     mainPanel(
                         plotOutput(outputId = "confPlot2")
                     )
                 ),
                 
                 # creer l'espace pour accueillir les references
                 fluidRow(column(width = 6,
                                 em("Data from CEVIPOF - CEVIPOF (2021)
                                    - F. Cassor, N. Sormani.")
                 )
                 )
            ),
        
        # tabPanel("Tab3",
        #          
        #          # creer l'espace pour accueillir le titre de l'application
        #          titlePanel("FRANCE - Confidence in the Prime Minister"),
        #          
        #          # sauts de ligne
        #          p(br(),
        #            br(),
        #          ),
        #          
        #          # creer l'espace pour accueillir les objets a visualiser
        #          sidebarLayout(
        #              
        #              # creer l'espace pour accueillir le menu deroulant des
        #              # annees a choisir de representer
        #              sidebarPanel(h4("Time filter"),
        #                           sliderInput(inputId = "year3",
        #                                       label = "Survey years to represent:",
        #                                       2009, 2018,
        #                                       value = c(2009, 2018), sep = ""),
        #                           
        #                           # creer l'espace pour accueillir le bouton
        #                           # de telechargement du graphique
        #                           fluidRow(
        #                               downloadButton(outputId = "DownloadChart3",
        #                                              label = "Download chart")
        #                           )
        #              ),
        #              
        #              # creer l'espace pour accueillir l'histogramme
        #              mainPanel(
        #                  plotOutput(outputId = "confPlot3")
        #              )
        #          ),
        #          
        #          # creer l'espace pour accueillir les references
        #          fluidRow(column(width = 6,
        #                          em("Data from CEVIPOF - CEVIPOF (2021)
        #                             - F. Cassor, N. Sormani.")
        #          )
        #          )
        # ),

        tabPanel("Tab3bis",
                 
                 # creer l'espace pour accueillir le titre de l'application
                 titlePanel("FRANCE - Confidence in the Prime Minister"),
                 
                 # sauts de ligne
                 p(br(),
                   br(),
                 ),
                 
                 # creer l'espace pour accueillir les objets a visualiser
                 sidebarLayout(
                   
                   # creer l'espace pour accueillir le menu deroulant des
                   # annees a choisir de representer
                   sidebarPanel(h4("Time filter"),
                                sliderInput(inputId = "year3bis",
                                            label = "Survey years to represent:",
                                            2009, 2018,
                                            value = c(2009, 2018), sep = ""),
                                
                                # instruction pour telecharger le graphique
                                p(em("To download the chart, please, click on the
                                     camera button 'Download plot as a png' at
                                     the left side of the bar that appears when
                                     moving the mouse to the right upper corner
                                     above the chart.")
                                  )
                                ),
                   
                   # creer l'espace pour accueillir l'histogramme
                   mainPanel(
                     plotlyOutput(outputId = "confPlot3bis")
                   )
                 ),
                 
                 # creer l'espace pour accueillir les references
                 fluidRow(column(width = 6,
                                 em("Data from CEVIPOF - CEVIPOF (2021)
                                    - F. Cassor, N. Sormani.")
                 )
                 )
        ),
        
        tabPanel("Tab4",
                 
                 # creer l'espace pour accueillir le titre de l'application
                 titlePanel("FRANCE - Confidence in the Prime Minister"),
                 
                 # sauts de ligne
                 p(br(),
                   br(),
                 ),
                 
                 # creer l'espace pour accueillir les objets a visualiser
                 sidebarLayout(  
                     
                     # creer l'espace pour accueillir le menu deroulant des
                     # variables a choisir de representer
                     sidebarPanel(
                         selectInput(inputId = "year4",
                                     label = "Survey year to represent:", 
                                     choices = levels(App_Data1$year)),
                         
                         # creer l'espace pour accueillir le bouton de
                         # telechargement du graphique
                         fluidRow(
                             downloadButton(outputId = "DownloadChart4",
                                            label = "Download chart")
                         )
                     ),
                     
                     # creer l'espace pour accueillir l'histogramme
                     mainPanel(
                         plotOutput(outputId = "confPlot4")
                     )
                 ),
                 
                 # creer l'espace pour accueillir les references
                 fluidRow(column(width = 6,
                                 em("Data from CEVIPOF - CEVIPOF (2021)
                                    - F. Cassor, N. Sormani.")
                 )
                 )
        ),
        
        tabPanel("Tab5",
                 
                 # creer l'espace pour accueillir le titre de l'application
                 titlePanel("FRANCE - Confidence in the Prime Minister"),
                 
                 # sauts de ligne
                 p(br(),
                   br(),
                 ),

                 # creer l'espace pour accueillir les objets a visualiser
                 sidebarLayout(  
                     
                     # creer l'espace pour accueillir le menu deroulant des
                     # variables a choisir de representer
                     sidebarPanel(
                         sliderInput(inputId = "year5",
                         label = "Year (click on the triangle button below to
                         animate the graphs)",
                         min = 2009, max = 2018,
                         value = 2009, # valeur initiale
                         animate = TRUE
                         # creer la possibilite de l'affichage dynamique des
                         # graphiques
                         ),
                     ),
                     
                     # creer l'espace pour accueillir l'histogramme
                     mainPanel(
                         plotOutput(outputId = "confPlot5")
                     )
                 ),
                 
                 # creer l'espace pour accueillir les references
                 fluidRow(column(width = 6,
                                 em("Data from CEVIPOF - CEVIPOF (2021)
                                    - F. Cassor, N. Sormani.")
                 )
                 )
        ),
        
        tabPanel("Tab6",
                 
                 # creer l'espace pour accueillir le titre de l'application
                 titlePanel("FRANCE - Confidence in the Prime Minister"),
                 
                 # creer l'espace pour accueillir les objets a visualiser
                 sidebarLayout(  
                     
                     # creer l'espace pour accueillir le menu deroulant
                     # des variables a choisir de representer
                     sidebarPanel(
                         helpText("Choose an item in the list below."),
                         selectInput(inputId = "confitem",
                                     label = "Variable :", 
                                     choices = levels(App_Data1$categorie)),
                         
                         # creer l'espace pour accueillir le bouton de
                         # telechargement du graphique
                         # fluidRow(
                         #   downloadButton(outputId = "DownloadChart6",
                         #                  label = "Download animated chart")
                         # )
                     ),
                     
                     # creer l'espace pour accueillir l'histogramme anime
                     mainPanel(
                         imageOutput(outputId = "confPlot6")
                     )
                     ),
                     
                     # creer l'espace pour accueillir les references
                     fluidRow(column(width = 6,
                                     em("Data from CEVIPOF - CEVIPOF (2021)
                                    - F. Cassor, N. Sormani.")
                     )
                     )
                 )
    )
)


#------------------------------------------------------------------------------#
# Bloc de construction des objets dynamiques des resultats (SERVER)            #
#------------------------------------------------------------------------------#

server <- function(input, output) {
    
    # objets reactifs sur le panneau "Menu"
    # telecharger la base de donnees au format utilisateur
    output$DownloadData <- downloadHandler(
      filename = function() {
        paste("Cevipof_PM_data_", Sys.Date(), ".xls", sep = "")
      },
      content = function(file) {
        classeur = createWorkbook()
        addWorksheet(classeur, sheetName = "Data")
        writeDataTable(classeur, sheet = "Data", App_Data0)
        saveWorkbook(classeur, file, overwrite = TRUE)
      }
    )

    
    # objets reactifs sur le panneau "tab1"
    # créer le tableau reactif
    output$table <- renderTable({
      tableau <- App_Data0 %>%
        mutate_at(vars(contains("confident")), pourcentage, digits=1)
      tableau
    })
    
    # creer le graphique reactif
    Chart1 <- reactive({
      App_Data1 %>%
        # creer le graphique et l'esthetique pour X, Y et la variable
        ggplot(aes(rev(categorie), percent, fill = categorie)) +
        # selectionner un histogramme avec des barres cote a cote
        geom_col(position = "dodge") +
        facet_wrap(~ year, ncol = 5) +
        # choisir le format francais pour l'axe des Y
        scale_y_continuous(labels = french_percent, limits = c(0, 0.52),
                           expand = c(0, 0)) +
        scale_fill_manual(values = cols) +
        # ajouter les titres
        labs(title = "Confidence in the Prime Minister from 2009 to 2018",
             caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
             x = "",
             y = "Percentage of respondents",
             fill = "") +
        # choisir la police de caractere du graphique
        theme_minimal(base_family = "Cambria") +
        # choisir le theme d'affichage detaille du graphique
        theme(
          legend.position = "top"  ,
          panel.grid.minor = element_blank(), 
          panel.grid.major.x = element_blank(),
          axis.line = element_line(color = "grey"),
          plot.title = element_text(face = "bold", 
                                    size = 18,
                                    hjust = 0.5),
          axis.text.x = element_blank(),
          axis.text.y = element_text(size = 12)
        )
    })
    # afficher le graphique reactif
    output$confPlot1 <- renderPlot({Chart1()})
    # exporter le graphique reactif au format png
    output$DownloadChart1 <- downloadHandler(
      file = paste("Cevipof_PMConfidence_Chart1_", Sys.Date(), ".png"),
      content = function(file) {
        ggsave(Chart1(), filename = file)
      })
    
    
    # objets reactifs sur le panneau "tab2"
    # creer le graphique reactif
    Chart2 <- reactive({
        App_Data1 %>% 
            # selectionner un sous ensemble des donnees par modalite de reponse
            subset(categorie == input$confdeg) %>%
            # creer le graphique et l'esthetique pour X, Y et la variable
            ggplot(mapping = aes(year, percent)) +
            # selectionner un histogramme avec des barres cote a cote
            geom_col(fill = "blue") +
            # ajouter les pourcentages au-dessus des barres
            geom_text(mapping = aes(y = percent, label = lbl),
                      col = "blue",
                      size = 4,
                      position = position_dodge(0.9),
                      vjust = -0.3) +
            # choisir le format francais pour l'axe des Y
            scale_y_continuous(labels = french_percent, limits = c(0, 0.52),
                               expand = c(0, 0)) +
        # ajouter les titres aux axes X et Y
        labs(title = input$confdeg,
             caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
             x = "Year",
             y = "Percentage of respondents",
             fill = "") +
            # choisir la police de caractere du graphique
            theme_minimal(base_family = "Cambria") +
            # choisir le theme d'affichage detaille du graphique
            theme(legend.justification = c(0, 1),
                  legend.position = c(0, 1),
                  legend.text = element_text(size=8),
                  panel.grid = element_blank(),
                  axis.line = element_line(color = "grey80"),
                  plot.title = element_text(face = "bold", 
                                            size = 18,
                                            hjust = 0.5),
                  axis.text.x = element_text(size = 12,
                                             vjust = 0.5),
                  axis.text.y = element_text(size = 12)
            )    
    })
    # afficher le graphique reactif
    output$confPlot2 <- renderPlot({Chart2()})
    # exporter le graphique reactif au format png
    output$DownloadChart2 <- downloadHandler(
        file = paste("Cevipof_PMConfidence_Chart2_", Sys.Date(), ".png"),
        content = function(file) {
            ggsave(Chart2(), filename = file)
        })
    
    
    # objets reactifs sur le panneau "tab3"
    # creer le graphique reactif
    # Chart3 <- reactive({
    #   App_Data1 %>%
    #     # selectionner un sous ensemble des donnees par annee
    #     subset(year %in% seq(input$year3[1], input$year3[2])) %>%
    #     # creer le graphique et l'esthetique pour X, Y et la variable
    #     ggplot(aes(year, percent, fill = categorie)) +
    #     # selectionner un histogramme avec des barres cote a cote
    #     geom_col(position = "dodge") +
    #     geom_text(aes(y = percent, label=lbl),
    #               size = 4,
    #               position = position_dodge(0.9),
    #               vjust = -0.3) +
    #     # choisir le format francais pour l'axe des Y
    #     scale_y_continuous(labels = french_percent, limits = c(0, 0.55),
    #                        expand = c(0, 0)) +
    #     scale_fill_manual(values = cols) +
    #     # ajouter les titres
    #     labs(title = paste0("Confidence in the Prime Minister from ", input$year3[1], " to ", input$year3[2]),
    #          caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
    #          x = "Year",
    #          y = "Percentage of respondents",
    #          fill = "") +
    #     # choisir la police de caractere du graphique
    #     theme_minimal(base_family = "Cambria") +
    #     # choisir le theme d'affichage detaille du graphique
    #     theme(
    #       legend.justification = c(0, 1),
    #       legend.position = c(0, 1),
    #       legend.text = element_text(size=8),
    #       panel.grid.minor = element_blank(), 
    #       panel.grid.major.x = element_blank(),
    #       axis.line = element_line(color = "grey80"),
    #       plot.title = element_text(face = "bold", 
    #                                 size = 18,
    #                                 hjust = 0.5),
    #       axis.text.x = element_text(size = 12),
    #       axis.text.y = element_text(size = 12),
    #     )
    # })
    # # afficher le graphique reactif
    # output$confPlot3 <- renderPlot({Chart3()})
    # # exporter le graphique reactif au format png
    # output$DownloadChart3 <- downloadHandler(
    #   file = paste("Cevipof_PMConfidence_Chart3_", Sys.Date(), ".png"),
    #   content = function(file) {
    #     ggsave(Chart3(), filename = file)
    #   })

        
    # objets reactifs sur le panneau "tab3bis"
    Chart3bis <- reactive({
      # remplir l'espace cree pour le graphique, avec le graphique choisi
      App_Data1 %>%
        # selectionner un sous ensemble des donnees par annee
        subset(year %in% seq(input$year3bis[1], input$year3bis[2])) %>%
        # creer le graphique et l'esthetique pour X, Y et la variable
        ggplot(mapping = aes(year, percent, fill = categorie)) +
        # selectionner un histogramme avec des barres cote a cote
        geom_col(position = "dodge") +
        # choisir le format francais pour l'axe des Y
        scale_y_continuous(labels = french_percent, limits = c(0, 0.55),
                           expand = c(0, 0)) +
        # remplir les barres avec la palette de couleurs definie
        scale_fill_manual(values = cols) +
        # ajouter les titres
        labs(title = paste0("Confidence in the Prime Minister from ",
                            input$year3[1], " to ", input$year3[2]),
             caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
             x = "Year",
             y = "Percentage of respondents",
             fill = "") +
        # choisir la police de caractere du graphique
        theme_minimal(base_family = "Cambria") +
        # choisir le theme d'affichage detaille du graphique
        theme(legend.justification = c(0, 1),
              legend.position = c(0, 1),
              legend.text = element_text(size=8),
              panel.grid.minor = element_blank(),
              panel.grid.major.x = element_blank(),
              axis.line = element_line(color = "grey80"),
              plot.title = element_text(face = "bold",
                                        size = 18,
                                        hjust = 0.5),
              axis.text.x = element_text(size = 12),
              axis.text.y = element_text(size = 12),
        )
    })
    # afficher le graphique reactif
    output$confPlot3bis <- renderPlotly({Chart3bis()})

        
    # objets reactifs sur le panneau "tab4"
    Chart4 <- reactive({
      App_Data1 %>% 
        # selectionner un sous ensemble des donnees par annee
        subset(year == input$year4) %>%
        # creer le graphique et l'esthetique pour X, Y et la variable
        ggplot(aes(rev(categorie), percent, fill = categorie)) +
        # selectionner un histogramme avec des barres cote a cote
        geom_col(position = "dodge") +
        geom_text(aes(y = percent, label=lbl),
                  size = 4, 
                  colour = cols,
                  position = position_dodge(0.9),
                  vjust = -0.3) +
        # choisir le format francais pour l'axe des Y
        scale_x_discrete("", labels = c("Not confident at all",
                                        "Somewhat not confident",
                                        "Somewhat confident",
                                        "Totally confident")) +
        scale_y_continuous(labels = french_percent, limits = c(0, 0.55),
                           expand = c(0, 0)) +
        scale_fill_manual(values = cols) +
        # ajouter les titres aux axes X et Y
        labs(title = input$year4,
             caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
             x = "",
             y = "Percentage of respondents",
             fill = "") +
        # ajouter le titre du graphique
        ggtitle(paste0("Confidence in the Prime Minister in ",
                       input$year4)) +
        # choisir la police de caractere du graphique
        theme_minimal(base_family = "Cambria") +
        # choisir le theme d'affichage detaille du graphique
        theme(
          legend.position = "none",
          panel.grid = element_blank(),
          axis.line = element_line(color = "grey80"),
          plot.title = element_text(face = "bold", 
                                    size = 18,
                                    hjust = 0.5),
          axis.text.x = element_text(size = 12, colour = rev(cols)),
          axis.text.y = element_text(size = 12)
        )
    })
    # afficher le graphique reactif
    output$confPlot4 <- renderPlot({Chart4()})
    # exporter le graphique reactif au format png
    output$DownloadChart4 <- downloadHandler(
      file = paste("Cevipof_PMConfidence_Chart4_", Sys.Date(), ".png"),
      content = function(file) {
        ggsave(Chart4(), filename = file)
      })
    
    
    # objets reactifs sur le panneau "tab5"
    # creer le graphique reactif
    Chart5 <- reactive({
      App_Data1 %>%
        # selectionner un sous ensemble des donnees par annee
        subset(year == input$year5) %>%
        # creer le graphique et l'esthetique pour X, Y et la variable
        ggplot(aes(rev(categorie), percent, fill = categorie)) +
        # selectionner un histogramme avec des barres cote a cote
        geom_col(position = "dodge") +
        geom_text(aes(y = percent, label=lbl), 
                  size = 4, 
                  colour = cols,
                  position = position_dodge(0.9),
                  vjust = -0.3) +
        # choisir le format francais pour l'axe des Y
        scale_x_discrete("", labels = c("Not confident at all",
                                        "Somewhat not confident",
                                        "Somewhat confident",
                                        "Totally confident")) +
        scale_y_continuous(labels = french_percent, limits = c(0, 0.55),
                           expand = c(0, 0)) +
        scale_fill_manual(values = cols) +
        # ajouter les titres aux axes X et Y
        labs(title = input$year5,
             caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
             x = "",
             y = "Percentage of respondents",
             fill = "") +
        # ajouter le titre du graphique
        ggtitle(paste0("Confidence in the Prime Minister from ",
                       input$year5, " to 2018")) +
        # choisir la police de caractere du graphique
        theme_minimal(base_family = "Cambria") +
        # choisir le theme d'affichage detaille du graphique
        theme(
          legend.position = "none"  ,
          panel.grid = element_blank(),
          axis.line = element_line(color = "grey80"),
          plot.title = element_text(face = "bold", 
                                    size = 18,
                                    hjust = 0.5),
          axis.text.x = element_text(size = 12, colour = rev(cols)),
          axis.text.y = element_text(size = 12)
        )
    })
    # afficher le graphique reactif
    output$confPlot5 <- renderPlot({Chart5()})
    
    
    # objets reactifs sur le panneau "tab6"
    # creer le graphique reactif
    output$confPlot6 <- renderImage({
  
        # creer un fichier gif pour sauvegarder le graphique en sortie
        outfile <- tempfile(fileext='.gif')
        
        p <- App_Data1 %>% 
            # creer le graphique et l'esthetique pour X, Y et la variable
            ggplot(mapping = aes(x = categorie, y = percent, fill = categorie))  +
            # selectionner un histogramme avec des barres cote a cote
            geom_col(position = "dodge") +
            # ajouter les pourcentages au-dessus des barres
            geom_text(mapping = aes(y = round(percent, digits = 1), label = lbl),
                      size = 4,
                      colour = COLS,
                      position = position_dodge(0.9),
                      vjust = -0.3) +
          # choisir le format francais pour l'axe des Y
          scale_x_discrete("", labels = c("Totally confident",
                                          "Somewhat confident",
                                          "Somewhat not confident",
                                          "Not confident at all")) +
          # choisir le format francais pour l'axe des Y
            scale_y_continuous(labels = french_percent, limits = c(0, 0.55),
                               expand = c(0, 0)) +
            # remplir les barres avec la palette de couleurs definie
            scale_fill_manual(values = cols) +
          # ajouter les titres aux axes X et Y
          labs(title = "Confidence in the Prime Minister in {closest_state}",
               caption = "Baromètre de la confiance politique, CEVIPOF, vagues 1 à 10",
               x = "",
               y = "Percentage of respondents",
               fill = "") +
          # ajouter une animation du graphique par annee
            transition_states(# definir une transition par annee
                              states = year,
                              # duree de la transition entre deux graphiques
                              transition_length = 30,
                              # duree de l'affichage de chaque graphique
                              state_length = 50,
                              # inclure une transition entre le dernier et le
                              # premier graphique lorsque l'animation redemarre
                              wrap = TRUE) +
            # choisir la police de caractere du graphique
            theme_minimal(base_family = "Cambria") +
            # choisir le theme d'affichage detaille du graphique
            theme(legend.position = "none",
                  panel.grid = element_blank(),
                  axis.line = element_line(color = "grey80"),
                  plot.title = element_text(face = "bold", 
                                            size = 22,
                                            hjust = 0.5),
                  axis.text.x = element_text(size = 9, colour = cols),
                  axis.text.y = element_text(size = 9)
            ) +
          # conserver la trace du graphique de l'annee qui precede
          shadow_wake(wake_length = 0.4, fill = NULL)
        
        # animer les graphiques crees dans p dans un fichier Gif en sortie        
        anim_save("outfile.gif", animate(p, renderer = gifski_renderer()))

        # renvoyer une liste contenant le fichier Gif cree
        list(src = "outfile.gif",
             contentType = 'image/gif'
        )
    },
    deleteFile = TRUE)
    
}


#------------------------------------------------------------------------------#
# Instruction de mise en oeuvre de l'application (shinyApp)                    #
#------------------------------------------------------------------------------#

shinyApp(ui = ui, server = server)


