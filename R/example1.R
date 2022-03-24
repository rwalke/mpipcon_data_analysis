# example 1
# get the data set from the edmond dataverse repository
# store a copy locally
# read the data set
# clean the date/time information
# create some example graphs with ggplot2
#
# Rainer Walke, MPIDR Rostock, 2022
# 
require(data.table)
require(lubridate)

require(dataverse)

require(vcd)
require(Cairo)
require(ggplot2)

power2 <- get_file_by_name(
  filename = "power_consumption_MPIDR_2020_2021.csv",
  dataset = "doi:10.17617/3.DHIBFN",
  server = "edmond.mpdl.mpg.de",
  original = TRUE
)

# store the file locally for later use
data_dir <- file.path("..", "..", "data")
if (!dir.exists(data_dir)) {dir.create(data_dir)}

writeBin(power2, file.path(data_dir,"power_consumption_MPIDR_2020_2021.csv"))

# read the time series
power3 <- fread(file.path(data_dir,"power_consumption_MPIDR_2020_2021.csv"),
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

# double check DST
check1 <- ymd_hms("2020-03-28 22:00:00", tz = "Etc/GMT-1")
power3[check1 < date3 & date3 < check1 +dhours(6)]

# show the power consumption histogram for 12 o'clock
h1 <- ggplot(power3[hour3==12 & minute3==0], aes(power1)) + geom_histogram(binwidth =  1, col="yellow") +
  scale_x_continuous("power consumption at 12 am (kW)")
h1

# check power consumption jumps
power3[,range(dpower1)]

h2 <- ggplot(power3, aes(dpower1)) + geom_histogram(binwidth =  0.2, col="yellow") +
  scale_x_continuous("power consumption jumps (kW)", limits=c(-8,8))
h2

h3 <- ggplot(power3, aes(dpower1)) + geom_histogram(binwidth =  0.2, col="yellow") +
  scale_x_continuous("power consumption jumps (kW)", limits=c(-30,-8))
h3

h4 <- ggplot(power3, aes(dpower1)) + geom_histogram(binwidth =  0.2, col="yellow") +
  scale_x_continuous("power consumption jumps (kW)", limits=c(8,30))
h4

# display the most significant power jumps
power3[15 < dpower1 | dpower1 < -15,]


# display the midday power consumption grouped by days of the week
s1 <- ggplot(power3[hour3==12 & minute3==0], aes(x=date3, y=power1, color=factor(wday3))) + geom_point() +
  scale_x_datetime("date (GMT-1)") +
  scale_y_continuous("power consumption at 12 am (kW)", limits=c(0,60)) +
  scale_color_discrete("wday")
s1

# define a directory for the figures and save the figures as png
figures_dir <- file.path("..", "figures")
if (!dir.exists(figures_dir)) {dir.create(figures_dir)}

CairoPNG(file.path(figures_dir, "example1_histogram_12am.png"), width = 480, height = 360)
h1
dev.off()

CairoPNG(file.path(figures_dir, "example1_point_12am.png"), width = 480, height = 360)
s1
dev.off()


