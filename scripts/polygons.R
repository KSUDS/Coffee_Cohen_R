pacman::p_load(tidyverse, sf, jsonlite, USAboundaries, leaflet, ggthemes)

httpgd::hgd()
httpgd::hgd_browse()

json_to_tibble <- function(x) {
    if(is.na(x))  return(x) #nolint
    parse_json(x) %>%
    enframe() %>%
    unnest(value)
} 

bracket_to_tibble <- function(x){ # nolint
    value <- str_replace_all(x, "\\[|\\]", "") %>%
        str_split(",", simplify = TRUE) %>%
        as.numeric()

    name <- seq_len(length(value))

    tibble::tibble(name = name, value = value)
}

#### uploading and formatting data #####

dat <- read_csv("data/core_poi-geometry-patterns.csv")

dat <- dat %>% filter(region == "GA")

dat_all <- dat %>%
    mutate(
        open_hours = map(open_hours, ~json_to_tibble(.x)),
        visits_by_day = map(visits_by_day, ~bracket_to_tibble(.x)),
        visitor_country_of_origin = map(visitor_country_of_origin, ~json_to_tibble(.x)), # nolint
        bucketed_dwell_times = map(bucketed_dwell_times, ~json_to_tibble(.x)),
        related_same_day_brand = map(related_same_day_brand, ~json_to_tibble(.x)), # nolint
        related_same_month_brand = map(related_same_month_brand, ~json_to_tibble(.x)), # nolint
        popularity_by_hour = map(popularity_by_hour, ~json_to_tibble(.x)),
        popularity_by_day = map(popularity_by_day, ~json_to_tibble(.x)),
        device_type = map(device_type, ~json_to_tibble(.x)),
        visitor_home_cbgs = map(visitor_home_cbgs, ~json_to_tibble(.x)),
        visitor_home_aggregation = map(visitor_home_aggregation, ~json_to_tibble(.x)) , # nolint
        visitor_daytime_cbgs = map(visitor_daytime_cbgs, ~json_to_tibble(.x))) %>% # nolint
    select(placekey, latitude, longitude, street_address, popularity_by_hour,
        city, region, postal_code, location_name, popularity_by_day,
        raw_visit_counts:visitor_daytime_cbgs, parent_placekey, open_hours)

ga <- USAboundaries::us_counties(states = "Georgia")

dat_sf <- dat_all %>% st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

dat_starbucks <- dat_sf %>% filter(location_name == "Starbucks")
dat_dunkin <- dat_sf %>% filter(location_name == "Dunkin'")


### simple plot ###
ggplot() +
    geom_sf(data = ga) +
    geom_sf(data = dat_dunkin, color = "#fcae1f") +
    geom_sf(data = dat_starbucks, color = "#0f410f") +
    theme_few()
ggsave(file = "basic_plot.png", width = 15, height = 6)

### formatting more data ###

ksu <- tibble(latitude = 34.037876, longitude = -84.58102) %>%
    st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# removing duplicate column names
ga <- ga %>%
select(-9) %>%
select(-13) %>%
      mutate(
        sf_area = st_area(geometry), # the awater variable is in m^2
        sf_middle = st_centroid(geometry)
    )


gaw <- ga %>%
    st_transform(4326) %>%
    mutate(
        aland_acres = aland * 0.000247105,
        awater_acres = awater * 0.000247105,
        percent_water = 100 * (awater / aland),
        sf_area = st_area(geometry),
        sf_center = st_centroid(geometry),
        sf_length = st_length(geometry),
        sf_distance = st_distance(sf_center, ksu),
        sf_buffer = st_buffer(sf_center, 24140.2), # 24140.2 is 15 miles
    )


store_in_county <- st_join(dat_sf, ga, join = st_within) %>%
    select(placekey, city, region, geometry, countyfp, name)

store_in_county_count <- store_in_county %>%
    as_tibble() %>%
    count(countyfp, name) %>%
    filter(!is.na(countyfp)) # drop the NA counts.

gaw <- ga %>%
    left_join(store_in_county_count, fill = 0)

dunkin_in_county <- st_join(dat_dunkin, ga, join = st_within) %>%
    select(placekey, city, region, geometry, countyfp, name)

dunkin_in_county_count <- dunkin_in_county %>%
    as_tibble() %>%
    count(countyfp, name) %>%
    filter(!is.na(countyfp)) # drop the NA counts.

gaw_dunkin <- ga %>%
    left_join(dunkin_in_county_count, fill = 0)

starbucks_in_county <- st_join(dat_starbucks, ga, join = st_within) %>%
    select(placekey, city, region, geometry, countyfp, name)

starbucks_in_county_count <- starbucks_in_county %>%
    as_tibble() %>%
    count(countyfp, name) %>%
    filter(!is.na(countyfp)) # drop the NA counts.

gaw_starbucks <- ga %>%
    left_join(starbucks_in_county_count, fill = 0)

### graphs to show raw visitor counts ###
gaw_dunkin %>%
ggplot() +
    geom_sf(aes(fill = n)) +
    scale_fill_continuous(trans = "sqrt") +
    geom_sf(data = filter(dat_dunkin, region == "GA"), color = "#d69214b0", aes(size = raw_visitor_counts), alpha=0.35) + # nolint
    theme_bw() + scale_fill_viridis_c(option = "inferno", begin = 0.1) +
    theme(legend.position = "left") +
    labs(fill = "Number of Dunkin'\nStores", size = "Raw Visitor Counts")
ggsave(file = "Number_of_Dunkin_stores_and_raw_visitor_counts.png", width = 15, height = 6)

gaw_starbucks %>%
ggplot() +
    geom_sf(aes(fill = n)) +
    scale_fill_continuous(trans = "sqrt") +
    geom_sf(data = filter(dat_starbucks, region == "GA"), color = "#055f05", aes(size = raw_visitor_counts), alpha=0.35) + # nolint
    theme_bw() +
    scale_fill_viridis_c(option = "mako", begin = 0.1) +
    theme(legend.position = "left") +
    labs(fill = "Number of Starbucks\nStores", size = "Raw Visitor Counts")
ggsave(file = "Number_of_Starbucks_stores_and_raw_visitor_counts.png", width = 15, height = 6)    

gaw %>%
ggplot() +
    geom_sf(aes(fill = n)) +
    scale_fill_continuous(trans = "sqrt") +
    geom_sf(data = filter(dat_dunkin, region == "GA"), color = "#d69214b0", aes(size = raw_visitor_counts), alpha=0.35) +
    geom_sf(data = filter(dat_starbucks, region == "GA"), color = "#055f05", aes(size = raw_visitor_counts), alpha=0.35) + # nolint
    theme_bw() +
    theme(legend.position = "left")
ggsave(file = "Number_of_stores_and_raw_visitor_counts.png", width = 15, height = 6)    

### formating data for vistior counts ##
    
dat_wc <- st_join(dat_sf, ga, join = st_within)

days_week_long <- dat_wc %>%
    filter(region == "GA") %>%
    as_tibble() %>% # notice this line to break the sf object rules.
    rename(name_county = name) %>%
    unnest(popularity_by_day) %>%
    select(placekey, city, region, contains("raw"),
        name, value, geometry, countyfp, name_county)

days_week <-  days_week_long %>%
    pivot_wider(names_from = name, values_from = value)

visits_day_join <- days_week %>%
    group_by(countyfp, name_county) %>%
    summarise(
        count = n(),
        Monday = sum(Monday, na.rm = TRUE) / count,
        Tuesday = sum(Tuesday, na.rm = TRUE) / count,
        Wednesday = sum(Wednesday, na.rm = TRUE) / count,
        Thursday = sum(Thursday, na.rm = TRUE) / count,
        Friday = sum(Friday, na.rm = TRUE) / count,
        Saturday = sum(Saturday, na.rm = TRUE) / count,
        Sunday = sum(Sunday, na.rm = TRUE) / count,
    ) %>%
    ungroup()

gaw2 <- gaw %>%
    left_join(visits_day_join %>% select(-name_county)) %>%
    replace_na(list(Monday = 0, Tuesday = 0, Wednesday = 0,
      Thursday = 0, Friday = 0, Saturday = 0, Sunday = 0))

gaw2 %>%
ggplot() +
    geom_sf(aes(fill = Saturday)) + 
    geom_sf(data = filter(dat_dunkin, region == "GA"), color = "#d69214b0") +
        geom_sf(data = filter(dat_starbucks, region == "GA"), color = "#055f05") +
    theme_bw() +
    theme(legend.position = "bottom") +
    labs(fill = "Average store traffic",
      title = "Saturday traffic'")
ggsave(file = "Average_store_traffic.png", width = 15, height = 6) 


### average traffic for starbucks ###

dat_wc_starbucks <- st_join(dat_starbucks, ga, join = st_within)

days_week_long_starbucks <- dat_wc_starbucks %>%
    filter(region == "GA") %>%
    as_tibble() %>% # notice this line to break the sf object rules.
    rename(name_county = name) %>%
    unnest(popularity_by_day) %>%
    select(placekey, city, region, contains("raw"),
        name, value, geometry, countyfp, name_county)

days_week_starbucks <-  days_week_long_starbucks %>%
    pivot_wider(names_from = name, values_from = value)

visits_day_join_starbucks <- days_week_starbucks %>%
    group_by(countyfp, name_county) %>%
    summarise(
        count = n(),
        Monday = sum(Monday, na.rm = TRUE) / count,
        Tuesday = sum(Tuesday, na.rm = TRUE) / count,
        Wednesday = sum(Wednesday, na.rm = TRUE) / count,
        Thursday = sum(Thursday, na.rm = TRUE) / count,
        Friday = sum(Friday, na.rm = TRUE) / count,
        Saturday = sum(Saturday, na.rm = TRUE) / count,
        Sunday = sum(Sunday, na.rm = TRUE) / count,
    ) %>%
    ungroup()

gaw2_starbucks <- gaw_starbucks %>%
    left_join(visits_day_join_starbucks %>% select(-name_county)) %>%
    replace_na(list(Monday = 0, Tuesday = 0, Wednesday = 0,
      Thursday = 0, Friday = 0, Saturday = 0, Sunday = 0))
      
gaw2_starbucks %>%
ggplot() +
    geom_sf(aes(fill = Saturday)) +
    geom_sf(data = filter(dat_starbucks, region == "GA"), color = "#055f05") +
  scale_fill_viridis_c(option = "mako", begin = 0.1) +
    theme_bw() +
    theme(legend.position = "left") +
    labs(fill = "Average store traffic",
      title = "Saturday traffic for Starbucks'")
ggsave(file = "Average_store_traffic_Starbucks.png", width = 15, height = 6)

########### average traffic for dunkin ###################

dat_wc_dunkin <- st_join(dat_dunkin, ga, join = st_within)

days_week_long_dunkin <- dat_wc_dunkin %>%
    filter(region == "GA") %>%
    as_tibble() %>% # notice this line to break the sf object rules.
    rename(name_county = name) %>%
    unnest(popularity_by_day) %>%
    select(placekey, city, region, contains("raw"),
        name, value, geometry, countyfp, name_county)

days_week_dunkin <-  days_week_long_dunkin %>%
    pivot_wider(names_from = name, values_from = value)

visits_day_join_dunkin <- days_week_dunkin %>%
    group_by(countyfp, name_county) %>%
    summarise(
        count = n(),
        Monday = sum(Monday, na.rm = TRUE) / count,
        Tuesday = sum(Tuesday, na.rm = TRUE) / count,
        Wednesday = sum(Wednesday, na.rm = TRUE) / count,
        Thursday = sum(Thursday, na.rm = TRUE) / count,
        Friday = sum(Friday, na.rm = TRUE) / count,
        Saturday = sum(Saturday, na.rm = TRUE) / count,
        Sunday = sum(Sunday, na.rm = TRUE) / count,
    ) %>%
    ungroup()

gaw2_dunkin <- gaw_dunkin %>%
    left_join(visits_day_join_dunkin %>% select(-name_county)) %>%
    replace_na(list(Monday = 0, Tuesday = 0, Wednesday = 0,
      Thursday = 0, Friday = 0, Saturday = 0, Sunday = 0))
      
gaw2_dunkin %>%
ggplot() +
    geom_sf(aes(fill = Saturday)) +
    geom_sf(data = filter(dat_dunkin, region == "GA"), color = "#d69214b0") +
    scale_fill_viridis_c(option = "inferno", begin = 0.1) +
    theme_bw() +
    theme(legend.position = "left") +
    labs(fill = "Average store traffic",
      title = "Saturday traffic for Dunkin'")
ggsave(file = "Average_store_traffic_Dunkin.png", width = 15, height = 6)
