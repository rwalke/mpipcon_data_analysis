* example 4 running mean
* get the data set from the edmond dataverse repository
* store a copy locally
* read the data set
* clean the date/time information
* define the data set as a time series
* calculate the running mean over a day and over a week
*
* Rainer Walke, MPIDR Rostock, 2022

* data source
* https://doi.org/10.17617/3.DHIBFN
copy https://edmond.mpdl.mpg.de/api/access/datafile/181741 ../../data/power_consumption_MPIDR_2020_2021.csv, replace

clear
import delimited using ../../data/power_consumption_MPIDR_2020_2021.csv, delimiter(";")

list in 1/6
drop in 1/4

* tidy energy data
codebook v2
gen energy1 = regexr(v2, ",", ".")
destring energy1, generate(energy2)

* power is energy per unit of time 
gen power1 = energy2 / 0.25
label variable power1 "power consumption in kW"

* compute the power difference
gen dpower1 = 0 in 1
replace dpower1 = power1 - power1[_n-1] in 2/L
label variable dpower1 "change of power consumption in kW within 15 minutes"

* tidy date data
* It is important to use the type 'double'!
gen double date2 = clock(v1, "DMYhm")
* format date2 %13.0f
format date2 %tc
label variable date2 "date/time in CET/CEST"

list in 1/3

* Prepare a second variable without daylight saving time (DST) changeover
gen date2diff = date2 - date2[_n-1]

tabulate date2diff
* . di 15*60/900000 is .001
replace date2diff = 900000 if date2diff == -2700000
replace date2diff = 900000 if date2diff == 4500000
tabulate date2diff

gen double date3 = date2 in 1
replace date3 = date3[_n-1] + date2diff in 2/L
format date3 %tc
label variable date3 "date/time in GMT-1"

* prepare a DST indicator
gen dst2 = (date2 != date3)
tabulate dst2

* extract parts from the datatime object for later use in analysis and graphs
gen hour3 = clockpart(date3, "hour")
gen minute3 = clockpart(date3, "minute")
gen wday3 = dow(dofc(date3))

label define wday_names 0 "Sun" 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thu" 5 "Fri" 6 "Sat"
label value wday3 wday_names


****
* define the data set as a time series
tsset date3, clocktime delta(15 minutes)

* compute a centered moving average (1 day has 96 units, 96 is not an odd number)
tssmooth ma pleft = power1, window(48 1 47)
tssmooth ma pright = power1, window(47 1 48)
generate smoothpower1 = (pleft + pright) / 2
label variable smoothpower1 "power consumption (moving average, 24 hours, kW)"

* decide to have an additive saisonality
generate seasonal1 = power1 - smoothpower1
label variable seasonal1 "power consumption (seasonal component, 24 hours, KW)"
histogram seasonal1, width(0.25) name(seasonal1, replace)

* show some examplary data
tsline smoothpower1 power1 if tin(1dec2021 12:00,8dec2021 12:00), xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(cols(1) ring(0) bplacement(north) size(small) region(lpattern(blank))) name(smoothpower1a, replace)

tsline smoothpower1 power1 if tin(1mar2020 12:00,31mar2020 12:00), xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(cols(1) ring(0) bplacement(north) size(small) region(lpattern(blank))) name(smoothpower1b, replace)

* compute a centered moving average for a whole week (7*96=672)
tssmooth ma pleft2 = power1, window(336 1 335)
tssmooth ma pright2 = power1, window(335 1 336)
generate smoothpower2 = (pleft2 + pright2) / 2
label variable smoothpower2 "power consumption (moving average, 7 days, kW)"

* again additive saisonality
generate seasonal2 = power1 - smoothpower2
label variable seasonal2 "power consumption (seasonal component, 7 days, kW)"
histogram seasonal2, width(0.25) name(seasonal2, replace)

* show some examplary data
tsline smoothpower2 smoothpower1 power1 if tin(1dec2021 12:00,8dec2021 12:00), xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(cols(1) ring(0) bplacement(north) size(small) region(lpattern(blank))) name(smoothpower2a, replace)

graph export ../figures/example4_smoothA.png, width(600) height(450) name(smoothpower2a) replace

tsline smoothpower2 smoothpower1 power1 if tin(1mar2020 12:00,31mar2020 12:00), xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(cols(1) ring(0) bplacement(north) size(small) region(lpattern(blank))) name(smoothpower2b, replace)

graph export ../figures/example4_smoothB.png, width(600) height(450) name(smoothpower2b) replace


* now as 2nd step dayly average
* compute a centered moving average (96)
tssmooth ma pleft21 = seasonal2, window(48 1 47)
tssmooth ma pright21 = seasonal2, window(47 1 48)
generate smoothpower21 = (pleft21 + pright21) / 2
label variable smoothpower21 "power consumption (seasonal 7 days, moving average 24 hours, kW)"

* stack the power consumption in three additive terms
gen power1m2m21 = power1 - smoothpower2 - smoothpower21
label variable power1m2m21 "power consumption (residuals, kW)"

* show some examplary data
tsline smoothpower2 smoothpower21 power1m2m21 if tin(1mar2020 12:00,31mar2020 12:00), xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(cols(1) size(small) region(lpattern(blank))) name(smoothpower21a, replace)

tsline smoothpower2 smoothpower21  if tin(15jan2020 12:00,15dec2021 12:00), xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(cols(1) size(small) region(lpattern(blank))) name(smoothpower21b, replace)

* ac power1
* pac power1

* ac D.power1
* pac D.power1
