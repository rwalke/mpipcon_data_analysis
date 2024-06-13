# example 6
# get the data set from the edmond dataverse repository
# store a copy locally
# read the data set
# clean the date/time information
# compute daily consumption histograms
# 
# Rainer Walke, MPIDR Rostock, 2024
# 
require(data.table)
require(lubridate)

require(dataverse)

require(vcd)
require(Cairo)
require(ggplot2)

data_file_name <- "power_consumption_MPIDR_2020_2023.csv"

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

# prepare a folder for storing figures
figures_dir <- file.path("..", "figures")
if (!dir.exists(figures_dir)) {dir.create(figures_dir)}

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

# resolve the time duplicates in the fall
power3[duplicated(date3, fromLast=TRUE)]
power3[duplicated(date3, fromLast=TRUE), date3 := date3 - dhours(1)]
power3[duplicated(date3, fromLast=TRUE)]

power3[, week3 := week(date3)]
power3[, month3 := month(date3)]
power3[, year3 := year(date3)]

power3[, wday3 := wday(date3, label=TRUE)]
power3[, day3 := floor_date(date3, "day")]

# double check DST
check1 <- ymd_hms("2020-03-28 22:00:00", tz = "Etc/GMT-1")
power3[check1 < date3 & date3 < check1 +dhours(6)]

check2 <- ymd_hms("2020-10-24 22:00:00", tz = "Etc/GMT-1")
power3[check2 < date3 & date3 < check2 +dhours(6)]


# create a year_month combination for better order
power3[, year_month:=paste0(year(date3), "-", month(date3))]
# fillin a 0
power3[, table(year_month)]
power3[, year_month:= sub("(-)(.$)","\\10\\2", year_month)]
power3[, table(year_month)]


tail(power3) # ignore the last data point (next year)

# sum the daily energy consumption

(power4 <- power3[year3<2024, .(year3=year3[1], month3=month3[1], wday3=wday3[1], year_month=year_month[1], energy_per_day = sum(energy1)), by=day3])

h1 <- ggplot(power4, aes(x=energy_per_day, group=year_month, fill=as.factor(year_month)))

h2 <- h1 + geom_histogram(binwidth=10, linewidth=0) +
  xlab("daily energy consumption (kWh)") + facet_wrap( ~year_month,  ncol=6) +
  scale_x_continuous(breaks=c(0,500,1000)) +
  theme(legend.position="none")
h2

# save it as an PDF image
CairoPDF(file.path(figures_dir ,"example6_dailyEnergy.pdf"), bg="transparent")
h2
dev.off()

# save it as an SVG image
CairoSVG(file.path(figures_dir ,"example6_dailyEnergy.svg"), width = 9, height = 6, bg="transparent")
h2
dev.off()

#
