/******************************************************************************/
/*** Crypto-HIV phase II - randomisation schedule *****************************/
/*** Armin Rauschenberger *****************************************************/
/**** Adjusted By Franck Ngangom on 20/01/2025 **********************************/
/******************************************************************************/
/*
This script generates the randomisation list for the Crypto-HIV phase II study.
The macrovariable "seed" defines the random seed, and the macrovariable "path"
defines the output directory. Running the macro "scheme" with arguments
"first_name" and "last_name" generates personalised copies of the randomisation
list, with visible and invisible watermarks.
*/

%let seed=20240802;

/* this is not the real seed */
*%let path=C:\Users\arauschenberger\Desktop\Crypto-HIV;
 %let path=\\shareccms.crp-sante.healthnet.lu\ccms\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-Phase2 Study\6 - Randomization;

proc format;
	value treatment 1='sustained-release (SR)' 2='immediate-release (IR)';
	value hospital 1='Kamuzu Central Hospital (Lilongwe, Malawi)' 
		2='Mwananyamala Referral Hospital (Dar es Salaam, Tanzania)' 
		3='Amana Referral Hospital (Dar es Salaam, Tanzania)';
run;

proc plan seed=&seed.;
	factors hospital=3 block=20 random treatment=4 random/noprint;
	output out=rand treatment nvals=(1 1 2 2) random;
	run;

proc sort data=rand;
	by hospital block;
run;

data rand;
	set rand;
	by hospital;

	if first.hospital then
		count=0;
	count + 1;
	output;
run;

data rand;
	set rand;
	RID=cat(put(hospital, z1.), put(count, z2.));
run;


/* Export the data to CSV */
proc export data=rand(drop=block count) 
		outfile="&path./randomisation_list.csv" dbms=csv 
		replace;
	putnames=yes;
run;


ods pdf file="&path./randomisation_list..pdf" style=grayscaleprinter;
title1 font=timesroman height=14pt "Randomisation list for all Hospitals";

proc report data=rand spanrows;
	by hospital;
	column hospital RID treatment;
	define hospital / order order=internal format=hospital. left;
	define RID / display left;
	define treatment / display format=treatment. left;
run;

ods pdf close;
title;


%macro scheme(first_name, last_name, hospital_number);
	ods pdf file="&path./randomisation_&last_name..pdf" style=grayscaleprinter;
	Options nodate;
	title1 font=timesroman 
		"Randomisation list for %sysfunc(putn(&hospital_number., hospital.))";
	title2 font=timesroman bold height=12pt "'A 10 week, open-label, randomized, controlled parallel-group trial to evaluate the comparative bioavailability, efficacy and safety of sustained-release flucytosine versus immediate-release flucytosine in adults with cryptococcal meningitis'";
	title3 font=timesroman height=10pt 
		"(random seed: &seed., confidential copy for &first_name. &last_name.)";
	footnote1 justify=left font=timesroman 
                 "Please note the SAP is not signed and the signed protocol is in version 1.0 dating from June 2, 2023.";
	footnote2 justify=left font=timesroman 
		"Please note that this is a watermarked copy.";
	footnote3 justify=left font=timesroman height=0.1 color=white 
		"This copy is for &first_name. &last_name..";
	proc report data=rand spanrows;
	    /* Filter based on hospital number */
		where hospital=&hospital_number.; 
		column RID treatment;
		define RID / display left;
		define treatment / display format=treatment. left;
	run;

	ods pdf close;
	title;
	footnote;
%mend scheme;

/* generate PDF for Hospital 1 */
%scheme(first_name=A, last_name=B , hospital_number=1);

/* PDF for Hospital 2 */
%scheme(first_name=C, last_name=D, hospital_number=2);

/* PDF for Hospital 3 */
%scheme(first_name=E, last_name=F, hospital_number=3);
