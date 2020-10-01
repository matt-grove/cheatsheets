#Initialise ----

library(sp)
library(rgeos)
library(rgdal)
library(raster)
library(leaflet)

# Read Shapefile ----
df <- readOGR("")

# Read CSV ----
df <- read.csv("df.csv")

# Spatialise ----
xy <- df[,c('longitude','latitude')]

df <- SpatialPointsDataFrame(coords = xy,
                              data = df,
                              proj4string = CRS("+init=epsg:4326"))

# Convert to correct CRS ----
df <- spTransform(df, CRS("+proj=longlat 
                          +datum=WGS84 
                          +no_defs 
                          +ellps=WGS84 
                          +towgs84=0,0,0 
                          "))

# Point in Polygon ----
points$name <- over(points, poly)$poly_col

# Check CRS ----
crs(df)

# Set 0 values to NA ----
df$name[df$name == 0] <- NA

# Set NA values to 0 ----
df$name[is.na(df$name)] <- 0


# Change to text only ----

paste0()
paste()


# Complete Cases ----
df <- df[complete.cases(df[ , 'column_name']),]

# Aggregate ----
df <- aggregate(df$CONSTANT, list(col_name = df$col_name), sum)



# Fancy Aggregate ----


temp <- cast(df, Constituency ~ Group_Descrip, sum, value = 'Constant')



# Match data to shapefile ----
shape@data <- data.frame(shape@data, 
                                  df[match(shape@data[, "shape_col"], 
                                              df[, "df_col"]), ])




# Leaflet Demo ----
leaflet() %>%
  addProviderTiles("CartoDB.Positron")



dfPal <- colorNumeric("YlOrRd", df$x)

leaflet(df) %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(color = ~dfPal(x), 
              stroke=F,
              fillOpacity = 0.5, 
              smoothFactor = 0) %>%
  addLegend(pal = dfPal, 
            values = ~x)




# Heatmap Polygon Creation ----

library(data.table)
library(KernSmooth)

# Extract just the data for manipulation
df_random <- data.table(random_clipped@data)

# Compute Kernal Density - on 30 30 grid size 
kde <- bkde2D(df_random[ , list(longitude, latitude)],
              bandwidth=c(.0075, .0100), gridsize = c(75,75))
# Extract the contour lines from the kde variable devised above
CL <- contourLines(kde$x1 , kde$x2 , kde$fhat)
# Extact the contour line levels
LEVS <- as.factor(sapply(CL, `[[`, "level"))
# Extract the number of contour line levels
NLEV <- length(levels(LEVS))
# Produce polygons using data produced above
pgons <- lapply(1:length(CL), function(i)
  Polygons(list(Polygon(cbind(CL[[i]]$x, CL[[i]]$y))), ID=i))
# Convert to spatial Polgons Dataframe
spgons = SpatialPolygons(pgons)
# Duplicate levels and convert to numeric
LEVS_LEG <- as.numeric(as.character(LEVS))

# calculte te colour pallete for leaflet plot using Color Brewer
rp_pallete <- colorNumeric("OrRd", LEVS_LEG)


leaflet(spgons) %>%
  addProviderTiles("CartoDB.Positron") %>%
  
  addPolygons(color = rp_pallete(LEVS_LEG), 
              stroke = FALSE, 
              weight = 10, 
              popup = as.character(LEVS_LEG)) %>%
  
  addLegend(pal = rp_pallete, 
            values = LEVS_LEG, 
            title = "Point Density")




# Geocode Singular Address ----
library(RJSONIO)
geocodeAdddress <- function(address) {
  
  url <- "http://maps.google.com/maps/api/geocode/json?address="
  url <- URLencode(paste(url, address, "&sensor=false", sep = ""))
  x <- fromJSON(url, simplify = FALSE)
  if (x$status == "OK") {
    # This has been altered to save it as a dataframe instead of list 
    out <- data.frame(longitude = x$results[[1]]$geometry$location$lng,
                      latitude = x$results[[1]]$geometry$location$lat)
  } else {
    out <- NA
  }
  Sys.sleep(0.2)  # API only allows 5 requests per second
  out
}


# Radial Plot displaying Barbour Data ----
Geo_Plot <- function(Address_Area, Radius_Meters) {
  
  address <- geocodeAdddress(paste(Address_Area))
  
  xy <- address[,c('longitude','latitude')]
  
  temp <- SpatialPointsDataFrame(coords = xy, 
                                 data = address,
                                 proj4string = CRS("+init=epsg:4326"))
  
  point_wgs84 <- spTransform(temp, CRS("+proj=longlat 
                                       +datum=WGS84 
                                       +no_defs 
                                       +ellps=WGS84 
                                       +towgs84=0,0,0 
                                       "))
  
  temp <- spTransform(temp, CRS("+init=epsg:27700"))
  
  # Quadsegs - higher the finer resolution
  buf = gBuffer(temp,width=Radius_Meters, quadsegs = 30)
  
  buf <- spTransform(buf, CRS("+proj=longlat 
                              +datum=WGS84 
                              +no_defs 
                              +ellps=WGS84 
                              +towgs84=0,0,0 
                              "))
  
  
  # This part was awkward - had to attach some sort of data to  
  # Distinguish the data that is within the radius!
  sdf <- data.frame(ID=row.names(buf)) 
  row.names(sdf) <- row.names(buf)
  buf <- SpatialPolygonsDataFrame(buf, sdf) 
  
  df$Binary <- over(df, buf)$ID
  df$Binary <- as.character(df$Binary)
  df <- df@data
  within_radius <- df[complete.cases(df[ , 'Binary']),]
  
  within_radius$Binary <- NULL
  
  xy <- within_radius[,c('longitude','latitude')]
  
  temp <- SpatialPointsDataFrame(coords = xy, 
                                 data = within_radius,
                                 proj4string = CRS("+init=epsg:4326"))
  
  other_points_wgs84 <- spTransform(temp, CRS("+proj=longlat 
                                              +datum=WGS84 
                                              +no_defs 
                                              +ellps=WGS84 
                                              +towgs84=0,0,0 
                                              "))
  
  
  
  leaflet(buf) %>%
    addProviderTiles("CartoDB.Positron") %>%
    addPolygons(fillOpacity = 0, color = 'red') %>%
    addCircleMarkers(data = point_wgs84, radius = 6, color = 'red', 
                     stroke = FALSE, fillOpacity = 0.35) %>%
    addCircleMarkers(data = other_points_wgs84, 
                     radius = 6, 
                     color = 'blue', 
                     stroke = FALSE, 
                     fillOpacity = 0.35, 
                     clusterOptions = markerClusterOptions())
  
  
  
}

Geo_Plot("Hinderton Point, Lloyd Dr, Ellesmere Port CH65 9HQ", 50000)


# Subset dataframe ----
df <- data.frame("Ptno" = df$Ptno,
                 "Status" = df$Status,
                 "Scheme" = df$Scheme)


df_geo <- df[,c("Ptno", "govt.region", "Site1",
                "Site2", "Site3", "Site4", 
                "Pcode", "Geocode", "Local.Authority")]



# Clip to Only ----

df <- df[df$col == "Liverpool",]


# Remove rows that contain: ----

df <- df[!grepl("OM", df$Stage),]



# Row Bind ----
df <- rbind(df, missing_ll)


# Multiple 
DF_COMPLETE <- do.call("rbind", list(d2012_07,
                                     d2013_07,
                                     d2014_07,
                                     d2015_07,
                                     d2016_07,
                                     d2017_07))


# Merge Two dataframes ----
df <- merge(df, 
            df2, 
            by.x = "col", 
            by.y = "col",
            all.x = TRUE)

# if else on column values ----
df <- transform(df, Stories = ifelse(Group == 1 & is.na(Stories), 2, Stories))


# Dates ----


# %Y: 4-digit year (1982)
# %y: 2-digit year (82)

# %m: 2-digit month (01)
# %B: month (January)
# %b: abbreviated month (Jan)

# %d: 2-digit day of the month (13)
# %A: weekday (Wednesday)
# %a: abbreviated weekday (Wed)

df$Completion_date <- as.Date(as.character(df$Completion_date), "%Y%m%d")

df$Month <- as.Date(cut(df$Plan_date,
                        breaks = "month"))


# Clip by singular date 
agg_1 <- agg_1[ agg_1$Date >= as.Date("2011-01-01"), ]
agg_1 <- agg_1[ agg_1$Date < as.Date("2017-05-01"), ]




# Monthly data - Keep only the major units if wanted
df$Month <- strftime(df$Plan_date, "%Y%m")
head(df$Month)

df$Month <- as.Date(df$Month, "%Y%m")

str(df$Plan_date)

df$month <- strftime(df$Plan_date, "%m")
df$yr <- strftime(df$Plan_date, "%Y")

# Create a list of dates
dates <- seq(min(y_date_count$CreatedDate), max(y_date_count$ClosedDate), by = "day")


# Count between dates (Used for LDC)
counts <- data.frame(date = dates,
                     count = sapply(dates, function(x) 
                       sum(x <= temp$ClosedDate & 
                             x >= temp$CreatedDate)))



# GGPlot ----

ggplot(data=agg_1, aes(x=Date, y=x)) +
  geom_line() +
  theme_bw()


facet_wrap( ~ Region, scales = "fixed")





















# County plotter - interactive map - clip data ----
County_Plotter <- function(County_name) {
  
  
  dir.create(paste0("PLOTS/County_breakdown/", County_name))
  
  temp <- aggregate(df$ones, list(Region = df$Region,
                                  County = df$County, 
                                  Category = df$Group_Descrip, 
                                  Date = df$Month_3), sum)
  
  temp <- temp[ temp$Date >= as.Date("2011-01-01"), ]
  temp <- temp[ temp$Date < as.Date("2017-05-01"), ]
  
  
  temp <- temp[temp$County == County_name,]
  
  
  x_lim_low <- as.Date("2011-01-01")
  x_lim_high <- as.Date("2017-05-01")
  
  # Split Graphs
  
  p <- ggplot(data=temp, aes(x=Date, y=x)) + 
    geom_bar(stat="identity", fill="steelblue") +
    xlab("Date") +
    ylab("Count") +
    theme_light() + 
    scale_x_date(
      labels = date_format("%Y-%m")) + 
    facet_wrap( ~ Category, scales = "free") + 
    expand_limits(x = c(x_lim_low, x_lim_high))
  
  ggsave(filename=paste0("PLOTS/County_breakdown/", County_name, "/", "Split_Graphs", ".jpg"), 
         plot=p, width = 40, height = 20, units = "cm")
  
  
  
  # Stacked Bar Graph
  
  q <- ggplot(data=temp, aes(x=Date, y=x, fill=Category)) + 
    geom_bar(stat="identity", position = "fill") +
    xlab("Date") +
    ylab("Count") +
    theme_light() + 
    scale_x_date(
      labels = date_format("%Y-%m")) 
  
  ggsave(filename=paste0("PLOTS/County_breakdown/", County_name, "/", "Stacked_Bar_Graph", ".jpg"), 
         plot=q, width = 40, height = 20, units = "cm")
  
  
  
  # Bar Graph
  
  a <- ggplot(data=temp, aes(x=Date, y=x, fill=Category)) + 
    geom_bar(stat="identity") +
    xlab("Date") +
    ylab("Count") +
    theme_light() + 
    scale_x_date(
      labels = date_format("%Y-%m")) 
  
  ggsave(filename=paste0("PLOTS/County_breakdown/", County_name, "/", "Bar_Graph", ".jpg"), 
         plot=a, width = 40, height = 20, units = "cm")
  
  
  
  
  
  
  
  
  
  
  temp <- aggregate(df$ones, list(Region = df$Region,
                                  County = df$County, 
                                  Category = df$SuperGroup, 
                                  Date = df$Month_3), sum)
  
  
  
  
  
  temp <- temp[ temp$Date >= as.Date("2011-01-01"), ]
  temp <- temp[ temp$Date < as.Date("2017-05-01"), ]
  
  
  temp <- temp[temp$County == County_name,]
  
  
  # 5 Groups Stacked
  
  b <- ggplot(data=temp, aes(x=Date, y=x, fill=Category)) + 
    geom_bar(stat="identity", position = "fill") +
    xlab("Date") +
    ylab("Count") +
    theme_light() + 
    scale_x_date(
      labels = date_format("%Y-%m")) 
  
  ggsave(filename=paste0("PLOTS/County_breakdown/", County_name, "/", "5_Group_Stacked_Bar_Graph", ".jpg"), 
         plot=b, width = 40, height = 20, units = "cm")
  
  
  
  # 5 Groups
  
  c <- ggplot(data=temp, aes(x=Date, y=x, fill=Category)) + 
    geom_bar(stat="identity") +
    xlab("Date") +
    ylab("Count") +
    theme_light() + 
    scale_x_date(
      labels = date_format("%Y-%m")) 
  
  ggsave(filename=paste0("PLOTS/County_breakdown/", County_name, "/", "5_Group_Bar_Graph", ".jpg"), 
         plot=c, width = 40, height = 20, units = "cm")
  
  
  
  
  
  
  
  
  
  
  
}



# Rename ----
names(Date_Swap12) <- c("Original", "Finish_12")

new_names <- c("this", "that", "these")
names(df) <- new_names




# Write csv ----
write.csv(df, "df.csv")


# List creator (For function list) ----

LIST_OF_GROUPS <- as.list(sort(unique(df_tempr$Group_Finer)))



# Buffer ----



temp <- data.frame(ID_no = c(101),
                   Latitude = c(53.48825),
                   Longitude = c(-2.08947))


head(temp)


# allocate the coordinates to xy (Lon Lat)
xy <- temp[,c('Longitude','Latitude')]

# convert to spatial points dataframe on the XY coordinates
temp <- SpatialPointsDataFrame(coords = xy, 
                               data = temp,
                               proj4string = CRS("+proj=longlat 
                                                 +datum=WGS84 
                                                 +no_defs 
                                                 +ellps=WGS84 
                                                 +towgs84=0,0,0 "))


temp <- spTransform(temp, CRS("+init=epsg:27700"))

buf = gBuffer(temp, width=500, quadsegs = 30)

plot(buf)

buf <- spTransform(buf, CRS("+proj=longlat 
                            +datum=WGS84 
                            +no_defs 
                            +ellps=WGS84 
                            +towgs84=0,0,0 
                            "))

buf <- spChFIDs(buf, paste("b", row.names(buf), sep="."))


sdf <- data.frame(OccupierID=temp$ID_no) 
row.names(sdf) <- row.names(buf)
buf <- SpatialPolygonsDataFrame(buf, sdf) 

head(buf)




# String Manipulation Split ----

# Split the string at the underscore and keep only left of it
as.character(lapply(strsplit(as.character(i), split="_"), "[", 1))

as.character(lapply(strsplit(as.character(m7_coeffs$term), split=":Postcode"), "[", 2))


# replace all blank spaces with underscore 
gsub(" ", "_", paste(i), fixed = TRUE)





# Linear Modelling ----


# Linear Model 

m0 <- lm('All_Count_LDC ~ Residential + Hotel_and_Catering + Road', df)


# Generalised Linear Model
# Log Linear

m0 <- glm(Occupied ~ Residential_ + 
            Medical_and_Healthcare_ + 
            Hotel_and_Catering_ + 
            as.factor(Date), 
          data = df,
          family=binomial(link="logit"))


# Poisson 

m0 <- glm(All_Count_LDC ~ Residential, df, family=poisson)


# Extract the coefficients and exponentials
m0 <- data.frame(B = m0$coefficients, expB = exp( m0$coefficients ) )


# Remove the intercept
# Replace with Postcode
m0 <- lm('All_Count_LDC ~ 0 + (Residential + Hotel_and_Catering):(Postcode)', df)


# Backwards stepwise AIC
MASS:::stepAIC(m0, direction="backward")



# qq Plot
car:::qqPlot(m1)

# Spread level plot
car:::spreadLevelPlot(m0)

# NCV Test
car:::ncvTest(m0)

# Vif test (Good)
car:::vif(m1)





# GWR ----


temp <- s_2015_01[complete.cases(s_2015_01@data[ , "Vacancy_Rate"]),] 

ad.bw <- gwr.sel(Vacancy_Rate ~ Residential_ + Human_Ameneties + Industry + Trans_Services, data = temp, adapt = TRUE)

gwrAD <- gwr(Vacancy_Rate ~ Residential_ + Human_Ameneties + Industry + Trans_Services, data = temp, adapt = ad.bw, gweight = gwr.bisquare, hatmatrix = T)



# Correlation ----


df_cut_count <- df[, c(3,4,5)]

x <- rcorr(as.matrix(df_cut_count))














# Sum of Rows ----


df$col_name <- rowSums(df[, c(1,2,3,4)])







# Sum of Columns ----


temp_all$CumSum <- cumsum(temp_all$x)




# tmap ----

tm_shape(NLD_prov) +
  tm_polygons("col_name") +
  tm_facets(by="multi_maps")




x <- tm_shape(Base_map) +
  tm_borders(col = "#e5e7e9", lwd = 10) +
  tm_shape(Base_map) +
  tm_polygons(col = "white") +
  tm_text("NAME", col = "black") + 
  tm_shape(gwr.map) +
  tm_bubbles(c("Trans_Services.1", "localR2"), 
             palette=list("-RdYlGn", "Greens"),  
             size = "Sizer",
             style=c("equal", "equal"),
             n=c(5, 5), 
             perceptual= T,
             border.lwd=0.5,
             border.col = "#aeb6bf", 
             legend.size.show=F,
             scale = c(2.5, 2.4),
             title.col = c("Coefficients - Transport S.", "R2 values")) + 
  tm_layout(legend.title.size = 1.4,
            legend.text.size = 1.2,
            legend.position = c("left","bottom"),
            legend.bg.color = "white",
            legend.bg.alpha = 1) + 
  tm_scale_bar(width = 0.1, size = 1.2)


# Take the Centroids of Polygons ----

centroids <- getSpPPolygonsLabptSlots(polys)



# Convert to GeoJSON ----





library(geojsonio)

df_geojson <- geojson_json(Regions_2)

geojson_write(df_geojson, file = "/Users/Grove/Desktop/SImplify/GB.geojson")






# Write Shapefile OGR ----



writeOGR(obj=Constituencies, 
         dsn="JOINED/", 
         layer="Constituencies", 
         driver="ESRI Shapefile")













# Merge & Dissolve Shapefiles GeoJSON----



getwd()



df <- readOGR("../splitBoundaries/peterRaworth.shp")
df <- spTransform(df, CRS("+init=epsg:27700"))
df <- gBuffer(df, byid=TRUE, width=0.00001)


region = gUnaryUnion(df)

region <- spTransform(region, CRS("+proj=longlat 
                                  +datum=WGS84 
                                  +no_defs 
                                  +ellps=WGS84 
                                  +towgs84=0,0,0 "))

plot(region)

row.names(region) = as.character(1:length(region))
a <- as.data.frame("boundary")
region = SpatialPolygonsDataFrame(region, a)

writeOGR(obj=region, 
         dsn="../dissolvedBoundaries/", 
         layer="peterRaworthDissolved", 
         driver="ESRI Shapefile")





a <- readOGR("../dissolvedBoundaries/danielGoldDissolved.shp")
b <- readOGR("../dissolvedBoundaries/darrenBedfordDissolved.shp")
c <- readOGR("../dissolvedBoundaries/garyCleggDissolved.shp")
d <- readOGR("../dissolvedBoundaries/jonathonHeadDissolved.shp")
e <- readOGR("../dissolvedBoundaries/jorianBryantDissolved.shp")
f <- readOGR("../dissolvedBoundaries/lisaSimeoneDissolved.shp")
g <- readOGR("../dissolvedBoundaries/louiseBowersDissolved.shp")
h <- readOGR("../dissolvedBoundaries/lucieArgerDissolved.shp")
i <- readOGR("../dissolvedBoundaries/michaelCollinsDissolved.shp")
j <- readOGR("../dissolvedBoundaries/peterRaworthDissolved.shp")


ab <- rbind(a,b,c,d,e,f,g,h,i,j)


str(ab)

plot(ab)



writeOGR(obj=ab, 
         dsn="../dissolvedBoundaries/", 
         layer="SalesRegions", 
         driver="ESRI Shapefile")









abc <- readOGR("../dissolvedBoundaries/SalesRegions.shp")
head(abc)


abcd <- readOGR("../originalBoundaries/PostalArea.shp")
abcd <- spTransform(abcd, CRS("+proj=longlat 
                              +datum=WGS84 
                              +no_defs 
                              +ellps=WGS84 
                              +towgs84=0,0,0 "))



df_geojson <- geojson_json(abcd)

geojson_write(df_geojson, file = "/Users/mg//Desktop/salesPostcodes.geojson")












