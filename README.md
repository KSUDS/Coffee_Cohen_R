# Coffee_Cohen_R

- __Project Purpose:__ 
- The purpose of this project was to analyze the difference of Starbucks stores and Dunkin' stores, as they are popular coffee brands and wanted to see in a sense which one was more popular. I used data from [Safegraph](https://www.safegraph.com/) selecting the stores in GA. I looked at which of the two brands has more locations on the map and which has more visitors rates on a specific sate. The skills I wanted to show was the ability to work with spatial data and having the variety of graphs. This project was for my own personal preference. 
- __Tools used:__ 
- I use R programming for this project and many packages: tidyverse, sf, jsonlite, USAboundaries, leaflet, ggthemes. The final scripts are [polygons.R](scripts/polygons.R) which shows the breaking down of the json tibbles and making the maps of the data and [time.R](scripts/time.R) which shows the process of creating the time plots for the average traffic in the data. 
- __Results:__ This is your conclusion.  Explain why your work matters.  How could others use it?  What are your next steps? Show some key findings.
The key finding I saw in the project was analyzing the time plots. Looking at the Dunkin' Plot ![Dunkin' Plot](https://raw.githubusercontent.com/ltcohen43/Coffee_Cohen_R/main/documents/Time_plot_Dunkin.png) you see how the prediction of the average visitor counts is pretty consist. Whereas looking at the Starbucks Plot ![Starbucks Plot](https://raw.githubusercontent.com/ltcohen43/Coffee_Cohen_R/main/documents/Time_plot_Starbucks.png) You see a peak in the beginning of the month then slowly decreasing towards the end of the month. But looking at the Starbucks plot, the x axis starts at 25 and goes to 40 where as the Dunkin' only goes up to 25 visitors. In conclusion, more people go to Stabucks on average for the of Saturday in the week, but Dunkin' has more consistent amount of customers coming in over the month. 



## Folder structure

```
- readme.md
- scripts
---- readme.md 
---- polygons.R
---- time.R
- data 
---- readme.md
---- brand_info.csv
---- core_poi-geometry-patterns.csv
---- GA-Starbucks-Dunkin-CORE_POI-GEOMETRY-PATTERNS-2021_09-2021-11-05.zip
---- home_panel_summary.csv
---- normalization_stats.csv
---- visit_panel_summary.csv
- documents
---- readme.md (notes while doing your project)
---- Average_store_traffic_Dunkin.png
---- Average_store_traffic_Starbucks.png
---- Average_store_traffic.png
---- basic_plot.png
---- Number_of_Dunkin_stores_and_raw_visitor_counts.png
---- Number_of_Starbucks_stores_and_raw_visitor_counts.png
---- Number_of_stores_and_raw_visitor_counts.png
---- Time_plot_Dunkin.png
---- Time_plot_Starbucks.png
```
