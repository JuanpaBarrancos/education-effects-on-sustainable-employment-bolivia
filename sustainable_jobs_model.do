clear all

******************************************************
* CONFIGURATION
******************************************************
* Set your working directory here
* cd "C:/Path/To/Your/Data"

* Load the database (Ensure the .dta file is in the folder)
* Note: This script assumes the data cleaning from 'employment_type.do' has been applied
use "ECE_4T15_1T25.dta", clear


** Data Preparation **


*****************************************
************* Household Size ************
*****************************************
	
xtset id_per_panel trim
egen num_ = count(id_per_panel), by(id_hog_panel trim)
rename num_ household_size
gen d_household_size=d.household_size
	
*****************************************
************ Years of Education *********
*****************************************

* Use 'aestudio' for estimation
gen estudios=aestudio
replace estudios=e if estudios==.

*****************************************
**************** Income *****************
*****************************************
egen num_ = count(id_per_panel), by(id_hog_panel trim)

* Sum of labor income of the household members for every trimester
egen ytotal = total(ylab), by(id_hog_panel trim)

* Income per person in the household for every trimester
gen yperperson=ytotal/num_

* Income quintiles generation
gen yperperson_quintile = .
bysort trim (yperperson): replace yperperson_quintile = ceil(_n / (_N/5)) if panel >= 14 & panel <= 37
gen ylab_quintile = .
bysort trim (ylab): replace ylab_quintile = ceil(_n / (_N/5)) if panel >= 14 & panel <= 37

*******************************************
************ Rename Variables *************
*******************************************

rename s1_16 civil_status
rename s1_03a age

***************************************************************************************************
* (2) General Adjustments
***************************************************************************************************

* Drop non-panel data observations (and rural area)
drop if panel==0
* Drop if age is unidentified
drop if age>=98
* Drop if education level is not specified
drop if niv_ed==9

**************************************************************************************************************************
********* Model Estimation **************
**************************************************************************************************************************

* Fixed Effects Logit Model: Sustainable Employment (Type 2)
xtlogit emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, fe
margins, dydx(aestudio)

* Informal Employment Determinants
xtlogit informal aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, fe
margins, dydx(aestudio)

* Green Job Determinants
xtlogit green_job aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, fe
margins, dydx(aestudio)

*********************************************************************************************
********************** Results Visualization ************************************************
*********************************************************************************************

* Accumulated general effect for different income levels
xtlogit emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, fe
margins, at(aestudio=(0(6)18)) over(yperperson_quintile)
marginsplot


***********************************************************************************************
************************************* Robustness Checks ***************************************
***********************************************************************************************

* Fixed Effects (FE) vs Random Effects (RE) - Hausman Test

xtlogit emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, re

xtreg emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, fe
estimates store fe_model_l
xtreg emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim, re
estimates store re_model_l
hausman fe_model_l re_model_l

***** Attrition Bias Correction (Heckman Approach) *****

* Count the number of periods each individual appears in the panel
by id_per_panel, sort: gen period_count = _N

* Define in_sample as having data for at least four periods
gen in_sample = (period_count >= 4)

* Heckprob execution to correct selection bias
heckprob emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim i.trim, select(in_sample= aestudio i.civil_status household_size ib3.yperperson_quintile i.trim) 
predict imr

* Final estimation with Inverse Mills Ratio (IMR)
xtlogit emp_sost_2 aestudio ib1.civil_status age household_size ib3.yperperson_quintile i.trim imr, fe
margins, dydx(aestudio)
