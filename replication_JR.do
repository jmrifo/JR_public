*****************************************************************************
//Replication File Johannes Renz Policy Evaluation Seminar
*****************************************************************************


//This Code generates Figure 1b)
**** Changes of Markup Dispersion for High vs Low Tariff Industries
*--------------------------------------------------------------------------------------------------

cd "/Users/johannesrenz/Library/Mobile Documents/com~apple~CloudDocs/Uni/PolEval/replication" //CHANGE CD HERE

use AEJ_ind_tariff_high-low.dta,clear
twoway (connected hightariffindustriesupper50 year, msize(large) msymbol(square) lwidth(thick) lpattern(solid)) (connected lowtariffindustrieslower50 year, msize(large) msymbol(diamond) lwidth(thick) lpattern(dash)), ytitle(Markup dispersion changes relative to 1998 (Theil), size(small))  xlabel(1999(1)2005) legend(size(small)) legend(pos(6)) xsize(5)

graph export "event_study_plot.png", as(png) name("Graph") replace



**** discussion

//anticipatory effect:

use AEJ_ind_DID_3-digit.dta,replace 


//From AEJ_Tables_Regressions.do
// DID regression: at 3-digit industry level 
// construct key variables


gen a01=avgtariff_ind3/100 if year==2001 //Tariff unit correction
by sic3, sort: egen tariff01= mean(a01) //gen average tariff
gen tariff=avgtariff_ind3/100 //Correct Tariff unit for all other years

//Generate logarithmatized variables
gen ln_theil=ln(theil) 
gen lnn=ln(n)
gen lnasset=ln(assets)


//Generate matrix to output the anticipatory effect table (Table 1)
matrix pre = J(10, 5,.) 
matrix colnames pre = Baseline 2001 2000 1999 All //Define column names 
matrix rownames pre = post02xtariff SE post01xtariff SE post00xtariff SE post99xtariff SE R2 Observations // define row names

// Generate a matrix to output level of significance of the estimations. this matrix will be used to enter significance * into tex (manually).
matrix sig = J(4,5,.) 

*----------------------------------------------------------------------------------------------------

gen post02= (year>2001) //Generate treatment period dummy
gen t01post02=tariff01*post02 // generate treatment variable

xtset sic3 year // set time series
xi: xtreg ln_theil t01post02 i.year, fe cluster(sic3) // baseline regression


//Enter into output matrix
matrix pre [1,1]= _b[t01post02]
matrix pre [2,1]= _se[t01post02]
matrix pre [9,1]= e(r2_w)
matrix pre [10,1]= e(N)

matrix sig [1,1]=  2*ttail(e(df_r),abs(( _b[t01post02]/_se[t01post02])))




** column 1: next year effect (still from Lu & Yu)

gen y2001= (year==2001) // generate treatment period dummy for one year earlier
gen t01y2001=tariff01*y2001 // generate treatment variable for one year earlier
xi: xtreg ln_theil t01post02 eg_3dt_city lnasset lnn determ* i.year t01y2001, fe cluster(sic3) // run regression


//Enter into output matrix

matrix pre [1,2]= _b[t01post02]
matrix pre [2,2]= _se[t01post02]

matrix pre [3,2]= _b[t01y2001]
matrix pre [4,2]= _se[t01y2001]

matrix pre [9,2]= e(r2_w)
matrix pre [10,2]= e(N)

matrix sig [1,2]=  2*ttail(e(df_r),abs(( _b[t01post02]/_se[t01post02])))
matrix sig [2,2]=  2*ttail(e(df_r),abs(( _b[t01y2001]/_se[t01y2001])))


//2000 anticipatory effect (similar to before)
gen y2000 = (year==2000)
gen t01y2000=tariff01*y2000
xi: xtreg ln_theil t01post02 eg_3dt_city lnasset lnn determ* i.year t01y2000, fe cluster(sic3)

matrix pre [1,3]= _b[t01post02]
matrix pre [2,3]= _se[t01post02]

matrix pre [5,3]= _b[t01y2000]
matrix pre [6,3]= _se[t01y2000]

matrix pre [9,3]= e(r2_w)
matrix pre [10,3]= e(N)

matrix sig [1,3]=  2*ttail(e(df_r),abs(( _b[t01post02]/_se[t01post02])))
matrix sig [3,3]=  2*ttail(e(df_r),abs(( _b[t01y2000]/_se[t01y2000])))


//1999 anticipatory effect (similar to before)

gen y1999 = (year==1999)
gen t01y1999=tariff01*y1999
xi: xtreg ln_theil t01post02 i.year t01y1999, fe cluster(sic3)


matrix pre [1,4]= _b[t01post02]
matrix pre [2,4]= _se[t01post02]


matrix pre [7,4]= _b[t01y1999]
matrix pre [8,4]= _se[t01y1999]

matrix pre [9,4]= e(r2_w)
matrix pre [10,4]= e(N)

matrix sig [1,4]=  2*ttail(e(df_r),abs(( _b[t01post02]/_se[t01post02])))
matrix sig [4,4]=  2*ttail(e(df_r),abs(( _b[t01y1999]/_se[t01y1999])))

// regression with all placebos together (similar to before)

xi: xtreg ln_theil t01post02 eg_3dt_city lnasset lnn determ* i.year t01y1999 t01y2000 t01y2001, fe cluster(sic3)

matrix pre [1,5]= _b[t01post02]
matrix pre [2,5]= _se[t01post02]

matrix pre [3,5]= _b[t01y2000]
matrix pre [4,5]= _se[t01y2000]

matrix pre [5,5]= _b[t01y2001]
matrix pre [6,5]= _se[t01y2001]

matrix pre [7,5]= _b[t01y1999]
matrix pre [8,5]= _se[t01y1999]

matrix pre [9,5]= e(r2_w)
matrix pre [10,5]= e(N)

matrix sig [1,5]=  2*ttail(e(df_r),abs(( _b[t01post02]/_se[t01post02])))
matrix sig [2,5]=  2*ttail(e(df_r),abs(( _b[t01y2001]/_se[t01y2001])))
matrix sig [3,5]=  2*ttail(e(df_r),abs(( _b[t01y2000]/_se[t01y2000])))
matrix sig [4,5]=  2*ttail(e(df_r),abs(( _b[t01y1999]/_se[t01y1999])))




// Round the values in the matrix
forvalues i = 1(1)10 {
    forvalues j = 1(1)5 {
        matrix pre[`i', `j'] = round(pre[`i', `j'], 0.001)
	
    }
}


// Round the values in the significance matrix
forvalues i = 1(1)4 {
    forvalues j = 1(1)5 {
        matrix sig[`i', `j'] = round(sig[`i', `j'], 0.001)
	
    }
}

// print matrix to check
matrix list pre
matrix list sig

// save results matrix as tex to turn into table

esttab matrix(pre) using table1, tex replace

esttab matrix(sig) using table1sig, tex replace //(entered manually)




*****************************************************************************
//potential bias on Theil index

//This part of the code gives useful information for Section 3.2 (Subgroup bias). Only the mean tariff is cited directly, while the rest serves to check distribution of SOE share across industries.
// The code does not generate output outside of STATA.



clear all
use AEJ_ind_DID_3-digit.dta,replace 


drop if soe ==.
drop if soe > 1 //there seem to be some miscalculations in the dataset where SOE share is above 1
sum soe, detail
kdensity soe
