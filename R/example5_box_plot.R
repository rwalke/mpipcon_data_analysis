# example 5
# get the data set from the edmond dataverse repository
# store a copy locally
# read the data set
# clean the date/time information
# compute weekly and monthly box plots
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

power2 <- get_file_by_name(
  filename = "power_consumption_MPIDR_2020_2022.csv",
  dataset = "doi:10.17617/3.DHIBFN",
  server = "edmond.mpdl.mpg.de",
  original = TRUE
)

# store the file locally for later use
data_dir <- file.path("..","..", "data")
if (!dir.exists(data_dir)) {dir.create(data_dir)}

writeBin(power2, file.path(data_dir,"power_consumption_MPIDR_2020_2022.csv"))

# read the time series
power3 <- fread(file.path(data_dir,"power_consumption_MPIDR_2020_2022.csv"),
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

power3[, week3 := week(date3)]
power3[, month3 := month(date3)]
power3[, year3 := year(date3)]

# double check DST
check1 <- ymd_hms("2020-03-28 22:00:00", tz = "Etc/GMT-1")
power3[check1 < date3 & date3 < check1 +dhours(6)]

# create some boxplots

p1MonthFacet <- ggplot(power3[year3<2023], aes(x=factor(month3), y=power1)) + geom_boxplot(fill="lightblue",outlier.size = 1.0) + facet_wrap(~year3) +
  scale_x_discrete("month") + scale_y_continuous("power consumption in kW")
p1MonthFacet

p1MonthFill <- ggplot(power3[year3<2023], aes(x=factor(month3), y=power1, fill=factor(year3))) + geom_boxplot(outlier.size = 1.0) +
  scale_x_discrete("month") + scale_y_continuous("power consumption in kW") + scale_fill_discrete("year")
p1MonthFill

p1WeekFill <- ggplot(power3[year3<2023], aes(x=factor(week3), y=power1, fill=factor(year3))) + geom_boxplot(outlier.size = 1.0) +
  scale_x_discrete("week", breaks=seq(1,52,2)) + scale_y_continuous("power consumption in kW") + scale_fill_discrete("year")
p1WeekFill

# define a directory for the figures and save the figures as png
figures_dir <- file.path("..", "figures")
if (!dir.exists(figures_dir)) {dir.create(figures_dir)}

CairoPNG(file.path(figures_dir, "example5_boxplotMonth1.png"), width = 720, height = 360)
p1MonthFacet
dev.off()

CairoPNG(file.path(figures_dir, "example5_boxplotMonth2.png"), width = 720, height = 360)
p1MonthFill
dev.off()

CairoPNG(file.path(figures_dir, "example5_boxplotWeek.png"), width = 900, height = 360)
p1WeekFill
dev.off()
