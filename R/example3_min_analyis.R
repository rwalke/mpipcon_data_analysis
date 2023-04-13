# example 3
# get the data set from the edmond dataverse repository
# store a copy locally
# read the data set
# clean the date/time information
# find the daily power consumption minimum
# do some illustrations
# 
# Rainer Walke, MPIDR Rostock, 2023
# 
require(data.table)
require(lubridate)

require(dataverse)

require(vcd)
require(Cairo)
require(ggplot2)

data_file_name <- "power_consumption_MPIDR_2020_2022.csv"

power2 <- get_file_by_name(
  filename = data_file_name,
  dataset = "doi:10.17617/3.DHIBFN",
  server = "edmond.mpdl.mpg.de",
  original = TRUE
)

# store the file locally for later use
data_dir <- file.path("..","..", "data")
if (!dir.exists(data_dir)) {dir.create(data_dir)}

writeBin(power2, file.path(data_dir, data_file_name))

# read the time series
power3 <- fread(file.path(data_dir, data_file_name),
                encoding = "UTF-8", sep=";", dec=",", header=FALSE, skip=4, col.names=c("date1","energy1"))
# data shows energy consumption per 15 minutes (0.25 hours)
# power is energy per unit of time 
power3[,power1:=energy1 / 0.25]

# compute the power difference
power3[, dpower1:= c(0,diff(power1))]


# use the time zone CET (and DST)
power3[, date2 := dmy_hm(date1, tz="CET")]
# double check for daylight saving time, see e.g. 2020-03-29
power3[, dst2 := dst(date2)]

# duplicate the date and fix the time zone to GMT-1
power3[, date3 := with_tz(date2, tz="Etc/GMT-1")]

power3[, hour3 := hour(date3)]
power3[, minute3 := minute(date3)]
power3[, wday3 := wday(date3, label=TRUE)]
power3[, day3 := floor_date(date3, "day")]

# double check DST
check1 <- ymd_hms("2020-03-28 22:00:00", tz = "Etc/GMT-1")
power3[check1 < date3 & date3 < check1 +dhours(6)]


# start the analysis of minimum power consumption
# compute the rolling mean over 4 hours (16 * 15 min)
power3[,p1_ma16 := frollmean(power1, 16, align = "center")]

# find the minimum for every day separately
power3[, p1_m16min := min(p1_ma16), by=day3]
power3[, p1_ismin := p1_m16min == p1_ma16]
# testing the multiple minima
power3[p1_ismin==TRUE,.N, by=day3][, table(N)]
power3[p1_ismin==TRUE,][,Nmin:=.N, by=day3][Nmin>1,.(date3,Nmin,p1_m16min)]

# keep the daily minimum, in case of multiple minima keep the first
power4 <- power3[p1_ismin==TRUE, .SD[1], by=.(day3,p1_ismin)]
table(power4[, duplicated(day3)])

power4[, table(hour3)]

# plot a histogram for the daily minimal power consumption (4 hour running mean)
# the weekends are different
p1min1 <- ggplot(power4, aes(p1_m16min, fill=wday3)) + geom_histogram(position="stack", binwidth =  0.2, color="gray") +
  scale_x_continuous("daily minimal power consumption (4 hour running mean, kW)") +
  scale_fill_viridis_d("wday")
p1min1

# plot a histogram for the hour of the day of the daily minimal power consumption (4 hour running mean)
p1min2 <- ggplot(power4, aes(hour3, fill=wday3)) + geom_histogram(position="stack", binwidth = 1, color="gray") +
  scale_x_continuous("hour of the day of minimal power consumption") +
  scale_fill_viridis_d("wday")
p1min2


# define a directory for the figures and save the figures as png
figures_dir <- file.path("..", "figures")
if (!dir.exists(figures_dir)) {dir.create(figures_dir)}

CairoPNG(file.path(figures_dir, "example3_histogram_daily_min.png"), width = 720, height = 360)
p1min1
dev.off()

CairoPNG(file.path(figures_dir, "example3_point_daily_min.png"), width = 480, height = 360)
p1min2
dev.off()



