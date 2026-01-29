clear all


* CONFIGURATION
* Set your working directory here
* cd "C:/Path/To/Your/Data"

* Load the database
use "ECE_4T15_1T25.dta", clear

******************************************************
**** Environmental Link Employment Analysis **********
******************************************************

* Drop observations with length less than 3
drop if strlen(s2_15acod) < 3

* Generate 3-digit ISCO variable
gen isco_3dig = substr(s2_15acod, 1, 3)

drop if isco_3dig=="010"
drop if isco_3dig=="020"
drop if isco_3dig=="030"

destring isco_3dig, replace

* Generate dummy variable for pollution
gen pollution_zero = 0

* Assign 1 if the 3-digit code has Pollution intensity = 0 in Annex I
replace pollution_zero = 1 if inlist(isco_3dig, ///
  111, 112, 121, 122, 131, 132, 133, 134, 141, 142, 143, ///
  212, 215, 216, 221, 222, 223, 224, 225, 226, 231, 232, 233, 234, 235, ///
  241, 242, 243, 251, 252, 261, 262, 263, 264, 265, ///
  314, 315, 321, 322, 323, 324, 325, 331, 332, 333, 334, 335, 341, 342, 343, ///
  351, 352, 411, 412, 413, 421, 422, 431, 432, 441, ///
  511, 512, 513, 514, 515, 516, 521, 522, 523, 524, 531, 532, 541, ///
  611, 612, 613, 622, 631, 632, 633, 634, ///
  712, 732, 754, 821, 832, 833, 835, ///
  911, 921, 933, 941, 951, 952, 961, 962)

* Verify
tab pollution_zero

* Generate Green Job dummy variable
gen green_job = 0

* Assign 1 if the code has Greenness intensity > 0 in Annex I
replace green_job = 1 if inlist(isco_3dig, ///
  112, 122, 131, 132, 211, 213, 214, 215, 216, ///
  241, 242, 243, 251, 263, 264, ///
  311, 313, 314, 325, 331, 332, 333, ///
  432, 712, 721, 722, 723, 754, 833, 931, 932, 933, 961, 962)
  
* Verify
tab green_job

* Generate Green Job variable with additional conditions
gen green_job_conditional = 0

* Assign 1 only if:
* - Greenness > 0 AND
* - If Pollution > 0, then Greenness > Pollution

* Codes where Greenness > 0 and Pollution = 0 (always qualify)
replace green_job_conditional = 1 if inlist(isco_3dig, ///
  112, 122, 131, 132, 215, 216, 241, 242, 243, 251, 263, 264, ///
  314, 325, 331, 332, 333, 432, 712, 833, 961)

* Codes where Greenness > 0 and Pollution > 0, but Greenness > Pollution
replace green_job_conditional = 1 if inlist(isco_3dig, ///
  213, 214, 311, 313, 721, 722, 723, 754, 931, 932, 933, 962)

* Verify
tab green_job_conditional

* Labels for pollution_zero
label define pollution_zero_label 0 "Pollution job" 1 "Non-pollution job"
label values pollution_zero pollution_zero_label

* Labels for green_job  
label define green_job_label 0 "Non-green job" 1 "Green job"
label values green_job green_job_label

* Labels for green_job_conditional
label define green_job_conditional_label 0 "Non-green job" 1 "Conditional green job"
label values green_job_conditional green_job_conditional_label

* Final Verification
tab pollution_zero
tab green_job
tab green_job_conditional


*****************************************
************* Informal Employment *******
*****************************************

gen informal=.
* Own-account workers and unpaid employers working in an enterprise without a taxpayer identification number a)
replace informal=1 if s2_18==2 & s2_23==3
replace informal=1 if s2_18==2 & s2_23==4 & s2_26<=5
replace informal=1 if s2_18==2 & s2_23==4 & s2_26<=5
replace informal=1 if s2_18==3 & s2_23==3
replace informal=1 if s2_18==3 & s2_23==4 & s2_26<=5
replace informal=1 if s2_18==3 & s2_23==4 & s2_26<=5

* Members of cooperatives that do not have a taxpayer identification number b)
replace informal=1 if s2_18==4 & s2_23==3
replace informal=1 if s2_18==4 & s2_23==4 & s2_26<=5
replace informal=1 if s2_18==4 & s2_23==4 & s2_26<=5

* Unpaid Family workers c)
replace informal=1 if s2_18==5

* Unpaid trainees d)
replace informal=1 if s2_18==6

* Employees that did not sign a contract, nor a formal agreement per product, and do not have a permanent position item e)
replace informal=1 if s2_18==1 & s2_21==3
replace informal=1 if s2_18==1 & s2_21==5

* Domestic worker f)
replace informal=1 if s2_18==7

* Formal employment
replace informal=0 if condact==1 & informal==.

* Labels
label var informal "Informal employment"
label define label_informal 0 "Formal" 1 "Informal"
label val informal label_informal

****************************************************************
********** Definition of Sustainable Employment ****************
****************************************************************

gen emp_sost_1 = 0
replace emp_sost_1=1 if informal==0 & pollution_zero==1

gen emp_sost_2 = 0
replace emp_sost_2=1 if informal==0 & green_job==1

gen emp_sost_3 = 0
replace emp_sost_3=1 if informal==0 & green_job_conditional==1

* Labels for emp_sost_1
label define emp_sost_1_label 0 "Other job" 1 "Formal Non-polluting Job"
label values emp_sost_1 emp_sost_1_label

* Labels for emp_sost_2
label define emp_sost_2_label 0 "Other job" 1 "Formal Green Job"
label values emp_sost_2 emp_sost_2_label

* Labels for emp_sost_3
label define emp_sost_3_label 0 "Other job" 1 "Conditional Formal Green Job"
label values emp_sost_3 emp_sost_3_label

* Verify
tab emp_sost_1
tab emp_sost_2
tab emp_sost_3

*****************************************
************ Comparative Table **********
*****************************************

svyset upm [pw=fact_trim], strata(estrato)

gen mujer = (s1_02==2)
label var mujer "(1=Female, 0=Male)"
gen indig = (s1_17==1)
label var indig "Indigenous Identity (1=Yes)"

tab green_job // 1=Green Job
tab informal // 1=Informal Job

* 2022 Analysis

* Sustainable Jobs
svy, subpop(if gestion==2022): mean ylab, over(emp_sost_2)
svy, subpop(if gestion==2022): mean tothrs, over(emp_sost_2)
svy, subpop(if gestion==2022): mean s1_03a, over(emp_sost_2)
svy, subpop(if gestion==2022): mean aestudio, over(emp_sost_2)
svy, subpop(if gestion==2022): mean mujer, over(emp_sost_2)
svy, subpop(if gestion==2022): mean indig, over(emp_sost_2)

* Green Jobs
svy, subpop(if gestion==2022): mean ylab, over(green_job)
svy, subpop(if gestion==2022): mean tothrs, over(green_job)
svy, subpop(if gestion==2022): mean s1_03a, over(green_job)
svy, subpop(if gestion==2022): mean aestudio, over(green_job)
svy, subpop(if gestion==2022): mean mujer, over(green_job)
svy, subpop(if gestion==2022): mean indig, over(green_job)

* Informal Jobs
svy, subpop(if gestion==2022): mean ylab, over(informal)
svy, subpop(if gestion==2022): mean tothrs, over(informal)
svy, subpop(if gestion==2022): mean s1_03a, over(informal)
svy, subpop(if gestion==2022): mean aestudio, over(informal)
svy, subpop(if gestion==2022): mean mujer, over(informal)
svy, subpop(if gestion==2022): mean indig, over(informal)

* 2023 Analysis

* Sustainable Jobs
svy, subpop(if gestion==2023): mean ylab, over(emp_sost_2)
svy, subpop(if gestion==2023): mean tothrs, over(emp_sost_2)
svy, subpop(if gestion==2023): mean s1_03a, over(emp_sost_2)
svy, subpop(if gestion==2023): mean aestudio, over(emp_sost_2)
svy, subpop(if gestion==2023): mean mujer, over(emp_sost_2)
svy, subpop(if gestion==2023): mean indig, over(emp_sost_2)

* Green Jobs
svy, subpop(if gestion==2023): mean ylab, over(green_job)
svy, subpop(if gestion==2023): mean tothrs, over(green_job)
svy, subpop(if gestion==2023): mean s1_03a, over(green_job)
svy, subpop(if gestion==2023): mean aestudio, over(green_job)
svy, subpop(if gestion==2023): mean mujer, over(green_job)
svy, subpop(if gestion==2023): mean indig, over(green_job)

* Informal Jobs
svy, subpop(if gestion==2023): mean ylab, over(informal)
svy, subpop(if gestion==2023): mean tothrs, over(informal)
svy, subpop(if gestion==2023): mean s1_03a, over(informal)
svy, subpop(if gestion==2023): mean aestudio, over(informal)
svy, subpop(if gestion==2023): mean mujer, over(informal)
svy, subpop(if gestion==2023): mean indig, over(informal)

* 2024 Analysis

* Sustainable Jobs
svy, subpop(if gestion==2024): mean ylab, over(emp_sost_2)
svy, subpop(if gestion==2024): mean tothrs, over(emp_sost_2)
svy, subpop(if gestion==2024): mean s1_03a, over(emp_sost_2)
svy, subpop(if gestion==2024): mean aestudio, over(emp_sost_2)
svy, subpop(if gestion==2024): mean mujer, over(emp_sost_2)
svy, subpop(if gestion==2024): mean indig, over(emp_sost_2)

* Green Jobs
svy, subpop(if gestion==2024): mean ylab, over(green_job)
svy, subpop(if gestion==2024): mean tothrs, over(green_job)
svy, subpop(if gestion==2024): mean s1_03a, over(green_job)
svy, subpop(if gestion==2024): mean aestudio, over(green_job)
svy, subpop(if gestion==2024): mean mujer, over(green_job)
svy, subpop(if gestion==2024): mean indig, over(green_job)

* Informal Jobs
svy, subpop(if gestion==2024): mean ylab, over(informal)
svy, subpop(if gestion==2024): mean tothrs, over(informal)
svy, subpop(if gestion==2024): mean s1_03a, over(informal)
svy, subpop(if gestion==2024): mean aestudio, over(informal)
svy, subpop(if gestion==2024): mean mujer, over(informal)
svy, subpop(if gestion==2024): mean indig, over(informal)

* 2025 Analysis

* Sustainable Jobs
svy, subpop(if gestion==2025): mean ylab, over(emp_sost_2)
svy, subpop(if gestion==2025): mean tothrs, over(emp_sost_2)
svy, subpop(if gestion==2025): mean s1_03a, over(emp_sost_2)
svy, subpop(if gestion==2025): mean aestudio, over(emp_sost_2)
svy, subpop(if gestion==2025): mean mujer, over(emp_sost_2)
svy, subpop(if gestion==2025): mean indig, over(emp_sost_2)

* Green Jobs
svy, subpop(if gestion==2025): mean ylab, over(green_job)
svy, subpop(if gestion==2025): mean tothrs, over(green_job)
svy, subpop(if gestion==2025): mean s1_03a, over(green_job)
svy, subpop(if gestion==2025): mean aestudio, over(green_job)
svy, subpop(if gestion==2025): mean mujer, over(green_job)
svy, subpop(if gestion==2025): mean indig, over(green_job)

* Informal Jobs
svy, subpop(if gestion==2025): mean ylab, over(informal)
svy, subpop(if gestion==2025): mean tothrs, over(informal)
svy, subpop(if gestion==2025): mean s1_03a, over(informal)
svy, subpop(if gestion==2025): mean aestudio, over(informal)
svy, subpop(if gestion==2025): mean mujer, over(informal)
svy, subpop(if gestion==2025): mean indig, over(informal)
