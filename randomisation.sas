
/******************************************************************************/
/*** Crypto-HIV phase II - randomisation schedule *****************************/
/*** Armin Rauschenberger *****************************************************/
/******************************************************************************/

/* define paths */

%let pathOut=C:\Users\arauschenberger\Desktop\Crypto-HIV;
%let seed=20240213; /* this is not the real seed */ 

/* randomisation schedule */ 

proc format;
	value treatment 1='control'
 					2='experimental';
	value country 	1='Tanzania'
					2='Malawi';
	value hospital 	1='Kamuzu Central Hospital (Lilongwe, Malawi)'
					2='Queen Elisabeth Central Hospital (Blantyre, Malawi)'
					3='Mwananyamala Hospital (Dar es Salaam, Tanzania)'
					4='Amana Hospital (Dar es Salaam, Tanzania)';
run;

proc plan seed=&seed.; 
	factors hospital=4 block=10 random treatment=6 random/noprint;
	output out=rand
	treatment nvals=(1 1 1 2 2 2)
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
	/*RID=catx('',put(hospital,z1.),put(count,z2.));*/
	RID=cat(put(hospital,z1.),put(count,z2.));
run;

%macro scheme(first_name,last_name);
ods pdf file="&pathOut./randomisation_&last_name..pdf" style=grayscaleprinter;
title1 font=timesroman "Randomisation list for";
title2 font=timesroman bold "'A 10 week, open-label, randomized, controlled parallel-group trial to evaluate the comparative bioavailability, 
efficacy and safety of sustained-release flucytosine versus immediate-release flucytosine in adults with cryptococcal meningitis'";
title3 font=timesroman "(random seed: &seed., confidential copy for &first_name. &last_name.)";
title4 font=timesroman color=red "THESE ARE DUMMY DATA - NOT MEANT FOR REAL USE";
footnote1 justify=left font=timesroman "control treatment: immediate release, experimental treatment: sustained release";
footnote2 justify=left font=timesroman "Please note that this is a watermarked copy.";
footnote3 justify=left font=timesroman height=0.1 color=white "This copy is for &first_name. &last_name..";
proc report data=rand spanrows;
	column hospital block RID treatment;
	define hospital/order order=internal format=hospital.;
	define block/order;
	define treatment/format=treatment.;
run;
ods pdf close;
footnote;
%mend scheme;

%scheme(first_name=Armin,last_name=Rauschenberger);

