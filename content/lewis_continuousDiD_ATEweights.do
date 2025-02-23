/*******************************************************************************
Code Title:    	calc_ATEweights_website.do
Description:   	calculate ATE weights for continuous DID & plot against actual
				treatment

Paper Citation: Lewis, Brittany Almquist. "Creditor rights, collateral reuse, 
				and credit supply." Journal of Financial Economics 149.3 (2023): 
				451-472. [Online Appendix B.2] 
Paper Link:		https://doi.org/10.1016/j.jfineco.2023.06.001
Appendix Link:	https://brittanyalewis.github.io/content/lewis_dealerliquidity_onlineappendix.pdf
Notes:		 	I thank Michael Gmeiner (LSE)for influential discussions. 
*******************************************************************************/

/*******************************************************************************
	setup
*******************************************************************************/

	#delimit ;
	clear;
	set more off, perm;
	set type double, perm;

/*******************************************************************************
	collapse data to county level
*******************************************************************************/


clear
global DATA "rootfilepath"
global ROOTPATH "rootfilepath"


global CODE "$ROOTPATH\filepath"
global INPUT "$ROOTPATH\filepath"
global OUTPUT "$ROOTPATH\filepath"
global SOURCE "$ROOTPATH\filepath"

/* Load in data */
use "$INPUT\dataset1.dta", clear

/* Calculate and drop duplicates */
	#delimit ;
	sort county_fips5dig_num year month;
	quietly by county_fips5dig_num:  gen county_duplicated = cond(_N==1,0,_n);
	/*
		 dup = 0       record is unique
         dup = 1       record is duplicate, first occurrence
         dup = 2       record is duplicate, second occurrence
         dup = 3       record is duplicate, third occurrence
         etc.
	*/
	#delimit ;
	tab county_duplicated;
	keep if county_duplicated == 0 | county_duplicated == 1;
	keep county_fips5dig_num;
	
	
	#delimit cr
	merge m:1 county_fips5dig_num using "$INPUT\dataset2.dta", keep(3)
	drop _merge

/*******************************************************************************
					generate histogram
*******************************************************************************/

*Create a variable for weights, to be filled in​​***
gen weight = .
***Create a local that takes on all the possible values of treatment, we will loop through this.
rename mkt_shr_num treatment
levelsof treatment, local(nm)

*Loop through values,
foreach x of local nm{
*Get the average if greater than or equal to that value.
*Use a summarize command and then store variables calculated.
sum treatment if treatment >=`x'
local mean1= r(mean)

*Get the average and variance unconditionally.
sum treatment 
local mean2= r(mean)
local var= r(sd)^2

*Create a binary variable for being greater than or equal to the value.
gen dummy_over = treatment >= `x'

**Get the probability of being greater than or equal.
sum dummy_over
local prob= r(mean)

***Filling in the weight for that treatment value.
replace weight = (`mean1'-`mean2')*`prob'/`var' if treatment == `x'

drop dummy_over
}

*to plot the line, treatment variable (y-axis) must be sorted, or it zig-zags
sort treatment
#delimit;
twoway (histogram treatment, fcolor(none) lcolor(black))
	   (line 	  weight  treatment if weight != ., lcolor(edkblue) lwidth(medthick) lpattern(dash)	),
			graphregion(color(white))
			bgcolor(white)
			ylabel(,glcolor(gs14))
			ytitle("Weight")
			xtitle("Actual Treatment Variable")
			legend(order(1 "Histogram" 2 "TWFE Weight") region(lcolor(white)))
			;
graph export "exportfilepath", as(pdf) replace;

	
