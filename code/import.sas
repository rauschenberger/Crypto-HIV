proc import datafile="&pathRand.\randomisation_list.csv"
		out=random
		dbms=csv;
run;

data random;
	set random;
	if treatment=1 then
		temp ='Sustained-Release (SR)';
	else if treatment=2 then
		temp='Immediate-Release (IR)';
	else
		put 'ERROR: invalid value for treatment';
	drop treatment;
	rename temp=treatment;
run;


/* Run the following code chunk to mask the treatment. */ 
/*
data random;
	set random;
	treatment = 'masked';
run;
*/

%prepare;

/* replace verbatim terms */ 

%macro add_terms(path=,code=,file=);
proc import datafile="&path.\&file."
    out=verbatim
    dbms=xlsx
	REPLACE;
run;
%if &code.=CM or &code.=PM %then %do;
	%let var_verb=CMTRT;
%end;
%else %if &code.=MH %then %do;
	%let var_verb=MHTERMPREP;
%end;
%else %if &code.=AE %then %do;
	%let var_verb=AETERM;
%end;
%else %if &code.=CE %then %do;
	%let var_verb=CETERM;
%end;
%else %do;
	%put ERROR;
%end;
data verbatim;
	set verbatim;
	rename Verbatim = &var_verb.;
	rename Patient_code = USUBJID;
run;
proc sort data=verbatim; by USUBJID &var_verb.; run;
proc sort data=&code.; by USUBJID &var_verb.; run;
data &code.;
	merge &code. verbatim;
	by USUBJID &var_verb.;
run;
%mend add_terms;

%add_terms(path=&pathClin,code=MH,file=Verbatims_MedDra_20260511_MH.xlsx);
%add_terms(path=&pathClin,code=AE,file=Verbatims_MedDra_20260805_AE.xlsx);
%add_terms(path=&pathClin,code=CM,file=Verbatims_WHODRUG_20260513_CM.xlsx);
%add_terms(path=&pathClin,code=PM,file=Verbatims_WHODRUG_20260513_PM.xlsx);
%add_terms(path=&pathClin,code=CE,file=Verbatims_MedDra_20260521_CE.xlsx);

%let treat_days='Day 1' 'Day 2' 'Day 3' 'Day 4' 'Day 5' 'Day 6' 'Day 7' 'Day 15';
%let post_weeks='Week 4' 'Week 6' 'Week 10';
