
/******************************************************************************/
/*** Crypto-HIV phase II - randomisation schedule *****************************/
/*** Armin Rauschenberger *****************************************************/
/******************************************************************************/

/* 
This script generates the randomisation list for the Crypto-HIV phase II study.
The macrovariable "seed" defines the random seed, and the macrovariable "path"
defines the output directory. Running the macro "scheme" with arguments
"first_name" and "last_name" generates personalised copies of the randomisation
list, with visible and invisible watermarks.
*/

%let seed=20240802; /* this is not the real seed */ 
%let path=C:\Users\arauschenberger\Desktop\Crypto-HIV;
/*%let path=\\shareccms.crp-sante.healthnet.lu\ccms\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-Phase2 Study\6 - Randomization*/

proc format;
	value treatment 1='sustained-release (SR)'
 					2='immediate-release (IR)';
	value country 	1='Tanzania'
					2='Malawi';
	value hospital 	1='Kamuzu Central Hospital (Lilongwe, Malawi)'
					2='Queen Elisabeth Central Hospital (Blantyre, Malawi)'
					3='Mwananyamala Hospital (Dar es Salaam, Tanzania)'
					4='Amana Hospital (Dar es Salaam, Tanzania)';
run;

proc plan seed=&seed.; 
	factors hospital=4 block=15 random treatment=4 random/noprint;
	output out=rand
	treatment nvals=(1 1 2 2)
	random;
run;

proc sort data=rand;
	by hospital block;
run;

data rand;
  set rand;
  by hospital;
  if first.hospital then count = 0;
  count + 1;
  output;
run;

data rand;
	set rand;
	/*SID=cat(put(hospital,z1.),put(count,z3.));*/
	RID=cat(put(hospital,z1.),put(count,z2.));
run;

%macro scheme(first_name,last_name);
ods pdf file="&path./randomisation_&last_name..pdf" style=grayscaleprinter;
title1 font=timesroman "Randomisation list for";
title2 font=timesroman bold "'A 10 week, open-label, randomized, controlled parallel-group trial to evaluate the comparative bioavailability, efficacy and safety of sustained-release flucytosine versus immediate-release flucytosine in adults with cryptococcal meningitis'";
title3 font=timesroman "(random seed: &seed., confidential copy for &first_name. &last_name.)";
title4 font=timesroman color=red "THESE ARE DUMMY DATA - NOT MEANT FOR REAL USE";
footnote1 justify=left font=timesroman "This randomisation list may be updated until the SAP is validated by the DMC and signed by all parties.";
footnote2 justify=left font=timesroman "Please note that this is a watermarked copy.";
footnote3 justify=left font=timesroman height=0.1 color=white "This copy is for &first_name. &last_name..";
proc report data=rand spanrows;
	column hospital RID treatment;
	define hospital/order order=internal format=hospital.;
	/*define block/order;*/
	define treatment/format=treatment.;
run;
ods pdf close;
footnote;
%mend scheme;

%scheme(first_name=Armin,last_name=Rauschenberger);
/*%scheme(first_name=Armin,last_name=Rauschenberger);*/
