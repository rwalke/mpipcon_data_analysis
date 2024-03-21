* example 2
* get the data set from the edmond dataverse repository
* store a copy locally
* read the data set
* clean the date/time information
* create some example graphs
*
* Rainer Walke, MPIDR Rostock, 2024

* data source
* https://doi.org/10.17617/3.DHIBFN
copy https://edmond.mpg.de/api/access/datafile/248438 ../../data/power_consumption_MPIDR_2020_2023.csv, replace

clear
import delimited using ../../data/power_consumption_MPIDR_2020_2023.csv, delimiter(";")

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

* prepare a histogram for the power consumption at noon
histogram power1 if hour3 == 12 & minute3 == 0, width(1) frequency xtitle(power consumption at 12 pm (noon, kW)) ytitle(count)

* prepare a scatter plot for th power consumption at noon
twoway (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 0, mcolor(%60) msize(tiny)) (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 1, mcolor(%60)  msize(tiny)) (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 2, mcolor(%60)  msize(tiny)) (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 3, mcolor(%60)  msize(tiny)) (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 4, mcolor(%60)  msize(tiny)) (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 5, mcolor(%60)  msize(tiny)) (scatter power1 date3 if hour3 == 12 & minute3 ==0 & wday3 == 6, mcolor(%60)  msize(tiny)), ytitle(power consumption at 12 pm (noon, kW)) xlabel(, labsize(6-pt) angle(horizontal) format(%tcCCYY-NN-DD)) legend(order(1 "Sun" 2 "Mon" 3 "Tue" 4 "Wed" 5 "Thu" 6 "Fri" 7 "Sat") position(7) ring(0) size(tiny))

****
