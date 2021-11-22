
pacman::p_load(tidyverse, sf, jsonlite, USAboundaries, ggthemes, geofacet) # nolint

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

dat_space_dunkin <- dat_dunkin %>%
    select(placekey, street_address, city, stusps = region, raw_visitor_counts) %>% # nolint
    filter(!is.na(raw_visitor_counts)) %>%
    group_by(stusps) %>%
    summarise(
        total_visitors = sum(raw_visitor_counts, na.rm = TRUE),
        per_store = mean(raw_visitor_counts, na.rm = TRUE),
        n_stores = n(),
        across(geometry, ~ sf::st_combine(.)),
    ) %>%
    rename(locations = geometry) %>%
    as_tibble()

ga2 <- ga %>%
    left_join(dat_space_dunkin)

dat_time_dunkin <- dat_dunkin %>%
    as_tibble() %>%
    select(placekey, street_address, city, region, raw_visitor_counts, visits_by_day) %>% # nolint
    filter(!is.na(raw_visitor_counts)) %>%
    unnest(visits_by_day) %>%
    rename(dayMonth = name, dayCount = value) %>%
    group_by(region, dayMonth) %>%
    summarize(
        dayAverage = mean(dayCount),
        dayCount = sum(dayCount),
        stores = length(unique(placekey))) %>%
    mutate(
        stores_label = c(stores[1], rep(NA, length(stores) - 1))
    )

dat_time_dunkin %>%
    ggplot(aes(x = dayMonth, y = dayAverage)) +
    geom_point() +
    geom_smooth(color = "#fcae1f") +
    labs(title = "Time Plot for Dunkin", x = "Day of the Month",
        y = "Average Visitor Counts") +
    theme_light()
ggsave(file = "Time_plot_Dunkin.png", width = 15, height = 6)

###########################################

dat_space_starbucks <- dat_starbucks %>%
    select(placekey, street_address, city, stusps = region, raw_visitor_counts) %>% # nolint
    filter(!is.na(raw_visitor_counts)) %>%
    group_by(stusps) %>%
    summarise(
        total_visitors = sum(raw_visitor_counts, na.rm = TRUE),
        per_store = mean(raw_visitor_counts, na.rm = TRUE),
        n_stores = n(),
        across(geometry, ~ sf::st_combine(.)),
    ) %>%
    rename(locations = geometry) %>%
    as_tibble()

ga2 <- ga %>%
    left_join(dat_space_starbucks)

dat_time_starbucks <- dat_starbucks %>%
    as_tibble() %>%
    select(placekey, street_address, city, region, raw_visitor_counts, visits_by_day) %>% # nolint
    filter(!is.na(raw_visitor_counts)) %>%
    unnest(visits_by_day) %>%
    rename(dayMonth = name, dayCount = value) %>%
    group_by(region, dayMonth) %>%
    summarize(
        dayAverage = mean(dayCount),
        dayCount = sum(dayCount),
        stores = length(unique(placekey))) %>%
    mutate(
        stores_label = c(stores[1], rep(NA, length(stores) - 1))
    )

dat_time_starbucks %>%
    ggplot(aes(x = dayMonth, y = dayAverage)) +
    geom_point() +
    geom_smooth(color = "#0f410f") +
    theme_light() +
    labs(title = "Time Plot for Starbucks", x = "Day of the Month",
        y = "Average Visitor Counts")
ggsave(file = "Time_plot_Starbucks.png", width = 15, height = 6)