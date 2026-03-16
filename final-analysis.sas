
/* The entry "D" means "not done" and the entry "A" means "not applicable". Replace both by NA! /*

/******************************************************************************/
/*** Crypto-HIV phase II study  ***********************************************/
/*** Armin Rauschenberger *****************************************************/
/******************************************************************************/

/* 
This SAS code is divided into four sections.
- Section 1: Setup
- Section 2: Macros
- Section 3: Formats
- Section 4: Analysis
*/

/*
This SAS script requires three manual interventions:
(1) Specify the paths to your input and output directories in Section 1.
(2) a) First run the SAS script before the WinNonlin part.
	b) Then calculate the PK parameters in WinNonlin (see below '%put Note:')
	c) Finally run the SAS script after the WinNonlin part.
(3) Copy-and-paste tables and figure from the results viewer (or use SAS ODS).
*/

/******************************************************************************/
/*** Section 1: Setup *********************************************************/
/******************************************************************************/

/* clean workspace */

/*
proc datasets library=work kill;
run;
dm 'odsresults; clear';
dm "log; clear; ";
options nosource;
options nonotes;
*/

proc datasets library=work kill nolist; run; quit;
proc catalog catalog=work.formats kill nolist; run; quit;
%symdel _all_ / nowarn;
ods _all_ close;
dm 'odsresults; clear';
dm "log; clear;";
options nosource nonotes;

/* define paths */

/* Specifying the paths to the input directories for the randomisation list (pathRand),
the clinical data (pathClin), and the pharmacokinetic data (pathPhar),
and specifying the path to the output directory for the tables and figures (pathOut).*/ 
%let pathRand=C:\Users\arauschenberger\Desktop\Crypto-HIV;
%let pathClin=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-Phase2 Study\4 - Data Management\7-Data transfers\Export files\30-Jul-2025_Franck;
%let pathPhar=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-02-CM (fed study)\4 - Data Management\7-Data transfers\Import files\15032023_Pharmetheus\0131FRM18_DNDi-5FC-02-CM_PK_20230315\0131FRM18_DNDi-5FC-02-CM_PK_20230315;
%let pathOut=C:\Users\arauschenberger\Desktop\Crypto-HIV\learning_SAS;

/******************************************************************************/
/*** Section 2: Macros ********************************************************/
/******************************************************************************/

/* import clinical data */
%macro import(path=,code=);
proc import datafile="&path.\&code._*"
    out=&code
    dbms=xlsx
	REPLACE;
run;
%mend import;
/*
Arguments: Expects a directory (e.g., path="C:\Users\myname\Desktop")
and a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Imports the file starting with 'code_' and ending with 'xlsx',
and stores it in the data set 'code'.
*/ 

/* extract random ID */
%macro add_rid(code=); 
data &code;
 	set &code;
 	RID = input(substr(USUBJID,index(USUBJID,'/')+1),best.);
run;
%mend add_rid;
/*
Arguments: Expects a CDISC abbreviation (e.g., code=VS for vital signs).
Description: Splits USUBJID (formatted as ABC/XYZ)
into two parts, extracts the second part (formatted as XYZ),
and adds this part to the dataset 'code' in the column 'RID'.
*/

/* sort by random ID */
%macro sort_rid(code=);
	proc sort data=&code;
		by RID;
	run;
%mend sort_rid;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Sorts the dataset 'code' by the random identifier (RID).
*/

/* add random info */
%macro add_seq(code=);
	data &code;
		merge &code(in=a) random(in=b);
		by RID;
		if a;
	run;
%mend add_seq;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Merges dataset 'code' and dataset 'random' by the random identifier (RID).
This adds information on the treatment sequence to dataset 'code'.
*/

/* import and process clinical data */
%macro prepare;
	%local code i;
	%let code = AE ART ARTT CE CM DD DI DM DS DV EG EX GC IE LB LP MH PE PM PR QUEST RANKIN VS; /* Also add files without code! */
	%do i = 1 %to %sysfunc(countw(&code));
    	%import(path=&pathClin,code=%scan(&code,&i));
		%add_rid(code=%scan(&code,&i));
		%sort_rid(code=%scan(&code,&i));
		%add_seq(code=%scan(&code,&i));
	%end;
%mend prepare;
/*
Arguments: -
Note: Loops through a list of abbreviations (e.g., 'code = VS DM' for vital signs and demographics).
Description: Prepares the datasets by importing the datasets, adding the random identifiers,
sorting the datasets by random identifiers and adding information on the treatment sequence.
*/

/* convert character to numeric */
%macro as_numeric(code=,var=);
data &code;
	set &code;
	temp = input(&var,best.);
	drop &var;
	rename temp=&var;
run;
%mend as_numeric;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs)
and a variable name (e.g., 'var=vsorres_weight').
Description: Converts character variable to numeric.
*/

/* derive treatment period */ 
/*
%macro add_period(code=);
	data &code.;
		set &code.;
		if VISIT in ('Treatment Period 1: 30 hrs PD','Unscheduled Treatment Period 1') then period='1';
		else if VISIT in ('Treatment Period 2: 30 hrs PD','Unscheduled Treatment Period 2') then period='2';
		else period = '';
	run;
%mend add_period;
*/
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Uses the variable 'VISIT' to create the variable 'period'.
*/

/* derive treatment */
/* 
%macro add_treat(code=);
	data &code.;
		set &code.;
    	if period='1' and seq='1 (AB)' then treatment='A';
		else if period='1' and seq='2 (BA)' then treatment='B';
		else if period='2' and seq='1 (AB)' then treatment='B';
		else if period='2' and seq='2 (BA)' then treatment='A';
		else treatment = '';
	run;
%mend add_treat;
*/
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Uses the variable for the period (1 or 2)
and the variable for the treatment sequence (AB or BA)
to create the variable for the treatment (A or B).
*/

/* re-order category levels */
%macro order_levels(code=,var=);
data &code.;
	set &code.;
	temp = input(&var.,&var._invalue.);
	&var._ = put(temp,&var._value.);
	format temp &var._value.;
	drop &var.;
	rename temp=&var.;
run;
%mend order_levels;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs)
and the name of a character variable (e.g., 'var=VSTEST').
Description: Given 'var=XXX', this macro assumes that
the formats 'XXX_invalue.' and 'XXX_value.' exist (see macro section).
This macro defines the internal order of the category levels.
It returns a numerical variable with labels (called 'XXX')
and a character variable of the labels (called 'XXX_').
Both variables have the specified order of the category levels,
'XXX' can be used for subsetting with the internal values (e.g., 'where XXX ne 0'),
and 'XXX_' can be used for subsetting with the labels (e.g., 'where XXX ne baseline')
*/

/*
%macro add_unit(code=);
	%local var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	data &code.;
		length &var_test_. $60;
		length measure $60;
		set &code.;
		if missing(&var_unit.) then measure = &var_test_.;
		else measure = cat(strip(&var_test_.),' (',strip(&var_unit.),')');
		&var_test_. = measure;
	run;
%mend add_unit;
*/

%macro sub_per(code=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	data &code.;
		length &var_unit. $60;
		length temp $60;
		set &code.;
		temp = tranwrd(strip(&var_unit.), '/', ' per ');
		drop &var_unit.;
		rename temp = &var_unit.;
	run;
%mend sub_per;
/* Replace "/" by " per ". */ 

%macro add_unit(code=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	data &code.;
		length temp $60;
		length &var_test. $60;
		set &code.;
		if missing(&var_unit.) then temp = &var_test.;
		else temp = cat(strip(&var_test.),' (',strip(&var_unit.),')');
		drop &var_test.;
		rename temp = &var_test.;
	run;
%mend add_unit;

/* define variable names TEST and SCORE */ 
%macro getvars(code=);
	%if &code.=VS %then %do;
		%let label='Vital Sign';
		%let var_test=VSTEST;
		%let var_test_=VSTEST_;
		%let state_by=RID VISIT VSPOS;
		%let var_judge=VSSTRESC;
		%let var_judge_=VSSTRESC_;
		%let var_score=VSORRES;
		%let var_unit=VSORRESU;
	%end;
	%else %if &code.=EG %then %do;
		%let label='Electrocardiogram';
		%let var_test=EGTEST;
		%let var_test_=EGTEST_;
		%let state_by=RID VISIT;
		%let var_judge=EGSTRESC1;
		%let var_judge_=EGSTRESC1_;
		%let var_score=EGORRES;
		%let var_unit=EGORRESU;
	%end;
	%else %if &code.=LB or &code.=LB_temp %then %do;
		%let label='Laboratory';
		%let var_test=LBTEST;
		%let var_test_=LBTEST_;
		%let state_by=RID VISIT;
		%let var_judge=LBCLSIG;
		%let var_judge_=LBCLSIG_;
		%if &code.=LB %then %do;
			%let var_score=LBORRES;
		%end;
		%else %if &code.=LB_temp %then %do;
			%let var_score=LBORRES_both;
		%end;
		%let var_unit=LBORRESU;
	%end;
	%else %do;
		%put ERROR;
	%end;
	%put label=&label.;
	%put var_test=&var_test.;
	%put var_test_=&var_test_.;
	%put state_by=&state_by.;
	%put var_score=&var_score.;
	%put var_judge=&var_judge.;
	%put var_judge_=&var_judge_.;
	%put var_unit=&var_unit.;
%mend getvars;


/* find patients with abnormal results */ 
%macro extract_ids_abnormal(code=,type=,visit=,test=,position=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
    data temp;
        set &code.;
        where VISIT_ in (&visit.) and not missing(&var_judge_.) and strip(&var_judge_.) not in ('Normal', '.', 'N/A') and not missing(RID); /* use numerical values */ 
		/*was in ('NCS','CS','Abnormal, NCS','Abnormal, CS') */ 
    run;
	%if %length(&type.)>0 %then %do;
		data temp;
			set temp;
			where type=&type.;
		run;
	%end;
	%if %length(&test.)>0 %then %do;
		data temp;
			set temp;
			where &var_test.=&test.;
		run;
	%end;
	%if %length(&position.)>0 %then %do;
		data temp;
			set temp;
			where VSPOS=&position.;
		run;
	%end;
    proc sql noprint;
        select distinct RID
        into :ids_abnormal separated by ','
        from temp;
    quit;
	proc datasets lib=work nolist;
        delete temp;
    quit;
	%let ids_abnormal=&ids_abnormal.;
	%put ids_abnormal=&ids_abnormal.;
%mend extract_ids_abnormal;
/*
Arguments: Expects one of two possible CDISC abbreviations
(either 'code=VS' for vital signs or 'code=EG' for electroencephalography),
and one or more visits (e.g., "visit='Screening Visit' 'Post-Study Visit'").
Description: Identifies patients with abnormal results at these visits
and saves their randomisation identifers in the macro variable 'ids_abnormal'.
*/

/* show results for some patients */ 
%macro extract_rows_abnormal(code=,type=,visit=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	data long;
		set &code.;
		if RID in (&ids_abnormal.);
		if VISIT_ in (&visit.);
	run;
	%if %length(&type.)>0 %then %do;
		data long;
			set long;
			where type=&type.;
		run;
	%end;
	proc sort data=long;
		by &state_by.;
	run;
	options validvarname=any;
	proc transpose data=long out=wide;
		by &state_by.;
		id &var_test.;
		/*idlabel &var_test_.;*/
		var &var_score.;
	run;
	options validvarname=v7;
	proc datasets lib=work nolist;
        delete long;
    quit;
%mend extract_rows_abnormal;
/*
Arguments: Expects one of two possible CDISC abbreviations (either 'code=VS' or 'code=EG'),
and one or more visits (e.g., visit='Screening Visit' 'Unscheduled').
*/

/* report with colour for extreme values */ 
%macro report(data=,title=,title2=,name=none);
	options validvarname=any;
	/*
	proc sort data=&data.;
		by RID VISIT;
	run;
	*/
	proc report data=&data. spanrows;
		%color(name=&name.);
		define RID/order order=internal;
		/*define VISIT/order order=internal;*/
		/*define VISIT_ /order=internal;*/
		/*%if &name.=EG %then %do;
			define PAGENAME / order order=internal;
		%end;*/
		/*define _NAME_/noprint;*/
		%title(type="listing",label=&title.);
		title2 &title2.;
	run;
	options validvarname=v7;
%mend;
/*
Arguments: Expects  a dataset (e.g., 'data=mydata') and a title for the output (e.g., "title='a title'").
The first optional argument can be changed from 'name=none' (default) to 'name=EG' to also order by PAGENAME.
And the second optional argument 'temp=TRUE' (default) to 'name=FALSE' to suppress the formatting for temperature.
Description: Adds colour for extreme values (see format section). Defines order of category levels.
*/

/* report patients with abnormal values*/ 
%macro list_abnormal(code=,type=,check_visit=,show_visit=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit ids_abnormal title;
	%getvars(code=&code.);
	%extract_ids_abnormal(code=&code.,type=&type.,visit=&check_visit.);
	%extract_rows_abnormal(code=&code.,type=&type.,visit=&show_visit.);
	/*%let show_visit_clean = %sysfunc(lowcase(%sysfunc(tranwrd(%sysfunc(compress(&show_visit.,%str('))),%str( ),%str( and )))));*/
	/*%let check_visit_clean = %sysfunc(lowcase(%sysfunc(dequote(&check_visit.))));*/
	%if %length(&type.)>0 %then %do;
		%let title = "%sysfunc(dequote(&type.)) Data at Visit &show_visit., if any Abnormal at Visit &check_visit.";
	%end;
	%else %do;
		%let title = "%sysfunc(dequote(&label.)) Data at Visit &show_visit., if any Abnormal at Visit &check_visit.";
	%end;
	%report(data=wide,title=&title.,name=&code.);
	proc datasets lib=work nolist;
        delete wide;
    quit;
%mend list_abnormal;
/*
Arguments: Expects CDISC abbreviation (either 'code=VS' or 'code=EG'),
the visit(s) to be checked for abnormal results (e.g., "check_visit='Screening Visit'"),
and the visit(s) to be shown (e.g., "show_visit='Unscheduled Screening'").
The optional argument can changed from "temp='TRUE'" (default) to "temp='FALSE'"
to omit the formatting for the variable temperature (if available).
Description: Identifies patients with abnormal results at one or more visits ('check_visit')
and shows the results for these patients at one or more visits ('show_visit').
*/ 

/* summarise vital signs - values */ 
%macro table_values(code=,test=,position=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	proc tabulate data=&code.;
		%if &code.=VS and %length(&position.)>0 %then %do;
			where VSPOS=&position. and &var_test.=&test.;
			class &var_test. VSPOS VISIT treatment / order=internal;
		%end;
		%else %do;
			where &var_test.=&test.;
			class &var_test. VISIT treatment / order=internal;		
		%end;
		/*
		%else %if &code.=LB %then %do;
			where &var_test.=&test.;
			class &var_test. VISIT treatment / order=internal;		
		%end;
		%else %do;
			%put ERROR;
		%end;
		*/
		var &var_score.; /*was VSORRES*/
		table 	VISIT * &var_score. * (mean std median min max n), /*was VSORRES*/
			treatment;
		%title(type="table",label="%sysfunc(dequote(&test.)) - Values"); /*%sysfunc(dequote(&position.))*/
		title2 '(summary statistics by visit and treatment)';
	run;
%mend table_values;
/*
Arguments: Expects a test ('Systolic Blood Pressure', 'Diastolic Blood Pressure' or 'Pulse Rate')
and a position (default 'Supine' or 'Standing').
Description: Summarises measurements for each time point (rows) and treatment (columns).
*/ 

%macro process_table(code=,tests=,position=);
	%local i test;
	%do i = 1 %to %sysfunc(countw(&tests, |));
  		/*%let test = %scan(&tests, &i, |);*/
    	%let test = %qscan(%superq(tests), &i, %str(|), q);
  		%table_values(code=&code.,test="&test",position=&position.);
  		%table_change(code=&code.,test="&test",position=&position.);
	%end;
%mend process_table;

/* calculate change */
%macro calcdiff(code=,test=,position=);
	%local var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	data DATA_DIFF;
		set &code.;
		%if &code.=VS and %length(&position.)>0 %then %do;
			where &var_test.=&test. and VSPOS=&position. and not missing(RID);
		%end;
		%else %do;
			where &var_test.=&test. and not missing(RID);
		%end;
	run;
	data DATA_DIFF;
  		do until(last.RID);
     		set DATA_DIFF;
     		by RID;
     		if treatment = 'immediate-release (IR)' then do;
        		if baseA = . then baseA = &var_score.;
        		change = &var_score. - baseA;
     		end;
			drop baseA;
     		else if treatment = 'sustained-release (SR)' then do;
        		if baseB = . then baseB = &var_score.;
				change = &var_score. - baseB;
    		end;
			drop baseB;
 		output;
		end;
	run;
%mend calcdiff;
/*
Arguments: Expects a test ('Systolic Blood Pressure', 'Diastolic Blood Pressure' or 'Pulse Rate')
and a position ('Supine' or 'Standing').
Description: Calculates the difference between the first values and the other values.
Use this macro to obtain the change with respect to baseline.
*/

/* summarise vital signs - change */
%macro table_change(code=,test=,position=);
	%calcdiff(code=&code.,test=&test.,position=&position.); /* returns DATA_DIFF*/
	proc tabulate data=DATA_DIFF;
		class VISIT treatment / order=internal;
		var change;
		table 	VISIT * change * (mean std median min max n),
			treatment;
		/*
		%let label = "%sysfunc(dequote(&position.)) %sysfunc(dequote(&test.)) - Change";
		*/
		%title(type="table",label="%sysfunc(dequote(&test.)) - Change");
		title2 '(with respect to screening visit,';
		title3 'summary statistics by visit and treatment)';
	run;
	proc datasets lib=work nolist;
        delete DATA_DIFF;
    quit;
%mend table_change;
/*
Arguments: Expects a test ('Systolic Blood Pressure', 'Diastolic Blood Pressure' or 'Pulse Rate')
and a position ('Supine' or 'Standing').
Description: Summarises change with respect to pre-dose for each time point (rows) and treatment (columns).
*/ 

/* plot trajectories */
%macro plot_traject(code=,check_visit=,test=,position=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit ids_abnormal;
	%getvars(code=&code.);
	%extract_ids_abnormal(code=&code.,visit=&check_visit.,test=&test.,position=&position.);
	data temp;
		set &code.;
		%if &code.=VS and %length(&position.)>0 %then %do;
			where &var_test.=&test. and VSPOS=&position.;
		%end;
		%else %do;
			where &var_test.=&test.;
		%end;
		if RID in (&ids_abnormal.);
	run;
	proc sort data=temp;
		by RID; /*included VSDTC*/  /* ALSO SORT BY VISIT? by RID VISIT */ 
	run;
	data temp;
		set temp;
		time_lag = lag(time);
		if missing(time) then do;
			time = time_lag + 0.5;
		end;
		drop time_lag;
	run;
	proc sgplot data=temp;
		series x=VISIT y=&var_score. / group=RID markers;
    	%title(type="figure",label="Trajectories of %sysfunc(dequote(&test.))"); /*%sysfunc(dequote(&position.))*/
		title2 '(for those abnormal at' &check_visit. ')';
    	xaxis label='time'; 
    	yaxis label='value';
   		keylegend / title='RID';
		%if %bquote(&test.)=%bquote("Systolic Blood Pressure (mmHg)") %then %do;
			refline 90 140 / axis=y lineattrs=(thickness=2);
		%end;
		%else %if &test.=%bquote("Diastolic Blood Pressure (mmHg)") %then %do;
			refline 45 90 / axis=y lineattrs=(thickness=2);
		%end;
		/*
		%if &code.=VS %then %do;
			%if %bquote(&position.)=%bquote('Sitting') and %bquote(&test.)=%bquote("Systolic Blood Pressure (mmHg)") %then %do;
				refline 90 140 / axis=y lineattrs=(thickness=2);
			%end;
			%if %bquote(&position.)=%bquote('Sitting') and &test.=%bquote("Diastolic Blood Pressure (mmHg)") %then %do;
				refline 45 90 / axis=y lineattrs=(thickness=2);
			%end;
		%end;
		*/
		/*refline 0 1 2 3 4 5 6 7 8 9 10 11 / axis=x lineattrs=(thickness=0.1 pattern=dash);*/
	run;
	proc datasets lib=work nolist;
        delete temp;
    quit;
%mend plot_traject;
/*
Arguments: Expects test 'Systolic Blood Pressure' or 'Diastolic Blood Pressure'
and position 'Supine' (default) or 'Standing'.
Description: Extracts data from the dataset 'VS'  for the individuals in 'ids_abnormal',
the position 'Supine' and the chosen test.
Sorts the extracted data by the sample identifier and the time point.
Replaces missing visit names by the visit name of the lagged time point.
Plots the measurements against the visit names, with one line for each patient.
*/

/* plot mean value or mean change */
%macro plot_internal(title=,title2=);
	/*
	data DATA_MEAN;
		set DATA_MEAN;
		where not missing(RID);
	run;
	*/ 
	proc sgplot data=DATA_MEAN;
		%title(type="figure",label=&title.);
		title2 &title2.;
		series x=visit y=mean / group=treatment markers markerattrs=(symbol=CircleFilled);
    	xaxis label='time';
    	yaxis label='value';
    	keylegend / title='treatment';
		highlow x=visit low=lclm high=uclm / group=treatment;
		scatter x=visit y=mean/yerrorlower=lclm yerrorupper=uclm group=treatment;
	run;
	proc datasets lib=work nolist;
        delete DATA_MEAN;
    quit;
%mend plot_internal;
%macro plot_mean_value(code=,test=,position=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	proc means data=&code. mean clm alpha=0.05 noprint;
		%if &code.=VS and %length(&position.)>0 %then %do;
			where not missing(RID) and &var_test.=&test. and VSPOS=&position.;
		%end;
		%else %do;
			where not missing(RID) and &var_test.=&test.;
		%end;
		var &var_score.;
		class treatment visit;
		output out=DATA_MEAN mean=mean lclm=lclm uclm=uclm;
	run;
	%plot_internal(title="Mean %sysfunc(dequote(&test.))",title2='(by treatment)'); /*&position.*/
	proc datasets lib=work nolist;
        delete DATA_MEAN;
    quit;
%mend plot_mean_value;
%macro plot_mean_change(code=,test=,position=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	%calcdiff(code=&code.,test=&test.,position=&position.);
	proc means data=DATA_DIFF mean clm alpha=0.05 noprint;
		%if &code.=VS and %length(&position.)>0 %then %do;
			where not missing(RID) and &var_test.=&test. and VSPOS=&position.;
		%end;
		%else %do;
			where not missing (RID) and &var_test.=&test.;
		%end;
		var change;
		class treatment visit;
		output out=DATA_MEAN mean=mean lclm=lclm uclm=uclm;
	run;
	%plot_internal(title="Mean Change in %sysfunc(dequote(&test.))",title2='(with respect to the screening visit, by treatment)'); /*  &position. */ 
	proc datasets lib=work nolist;
        delete DATA_MEAN;
    quit;
%mend plot_mean_change;
/*
Arguments: Expects test='Systolic Blood Pressure', test='Diastolic Blood Pressure' or test='Pulse Rate',
and expects position='Supine' (default) or position='Standing'.
Description: Extracts the data from dataset 'VS' for the selected position and the selected test.
Optionally (plot_mean_change), computes the differences with respect to the pre-dose measurement.
Calculates the means of these measurement for the two treatments (A and B)
and the different time points (pre-dose, 2/4/6/48 hours postdose),
as well as the lower and upper confidence limits for these means.
Plots the results.
*/

%macro process_trend(code=,tests=,position=);
	%local i test;
	%do i = 1 %to %sysfunc(countw(&tests, |));
  	%let test = %scan(&tests, &i, |);
  		%plot_mean_value(code=&code.,test="&test",position=&position.);
  		%plot_mean_change(code=&code.,test="&test",position=&position.);
	%end;
%mend process_trend;

%macro process_traject(code=,check_visit=,tests=,position=);
	%local i test;
	%do i=1 %to %sysfunc(countw(&tests, |));
	%let test = %scan(&tests, &i, |);
		%plot_traject(code=&code.,check_visit=&check_visit.,test="&test",position=&position.);
	%end;
%mend process_traject;


%macro tabulate(code=,type=,visit=);
	%local label var_test var_test_ state_by var_score var_judge var_judge_ var_unit;
	%getvars(code=&code.);
	proc tabulate data=&code.;
		%if %length(&type.)>0 %then %do;
			%title(type="table",label="%sysfunc(dequote(&type.)) Data at %sysfunc(dequote(&visit.)) Visit by Treatment");
		%end;
		%else %do;
			%title(type="table",label="%sysfunc(dequote(&label.)) Data at %sysfunc(dequote(&visit.)) Visit by Treatment");
		%end;
		title2 "(top: number and percentage of normal, NCS abnormal, and CS abnormal;";
		title3 "bottom: summary statistics of numerical values)";
		%if %length(&type.)>0 %then %do;
			where type=&type. and VISIT_=&visit.;
		%end;
		%else %do;
			where VISIT_=&visit.;
		%end;
		var &var_score.;
		class treatment VISIT_ &var_test. &var_judge.;
		table	&var_test. * &var_judge. * (n pctn<&var_judge.>='%')
				&var_test. * &var_score. * (mean std median min max n),
				treatment all='total';
	run;
%mend tabulate;

/* perform mixed modelling */ 
%macro mixmod(outcome=,data=PKpars,class=rid treatment period,fixed=treatment period treat,random=rid(treat),lsmeans=treat,alpha=0.10);
	proc mixed data=&data.;
		Class &class.;
		Model &outcome.= &fixed. / ddfm=kr; /* was seq period treat  */ 
		Random &random. / type=vc; /* was rid(seq) */
		lsmeans &lsmeans. /cl alpha=0.10; /* was treat*/ 
		Estimate 'diff B-A' treat -1 1/cl alpha = &alpha.;
		ods exclude CovParms ConvergenceStatus ClassLevels Dimensions Estimates FitStatistics IterHistory LSMeans ModelInfo NObs Tests3;
		ods output CovParms=random Tests3=fixed LSMeans=means Estimates=diff;
	run;
	proc print data=random;
		id CovParm;
		var Estimate;
		title &outcome.;
	run;
	title;
	proc print data=fixed;
		id Effect;
		var FValue ProbF;
	run;
	data means;
		set means;
		expEstim=exp(Estimate);
		expLower=exp(Lower);
		expUpper=exp(Upper);
	run;
	proc print data=means;
		id treat;
		var expEstim expLower expUpper;
	run;
	data diff;
		set diff;
		expEstim=exp(Estimate);
		expLower=exp(Lower);
		expUpper=exp(Upper);
	run;
	proc print data=diff;
		id Label;
		var expEstim expLower expUpper;
	run;
%mend mixmod;
/* 
Arguments: Specify the outcome (e.g. 'logCmax', 'logAUClast' or 'logAUCinf').
Description: Performs mixed modelling, returns estimated variance of random effects,
estimated fixed effects, geometric mean ratio (misnomer!) for binary effect of interest
*/



/******************************************************************************/
/*** Section 3: Formats *******************************************************/
/******************************************************************************/

proc format;
	invalue PAGENAME_invalue
		'ECG' = 0
 		'ECG - 2 hours post-dose - only for Ancotil' = 2
 		'ECG - 4 hours post-dose - only for Flucitosine' = 4
 		'ECG - 8 hours (2 hours after 2nd dose Ancotil)' = 8
		'ECG - 48 hours post-dose' = 48
		;
	value PAGENAME_value
		0 = 'ECG'
 		2 = 'ECG - 2 hours post-dose - only for Ancotil'
 		4 = 'ECG - 4 hours post-dose - only for Flucitosine'
 		8 = 'ECG - 8 hours (2 hours after 2nd dose Ancotil)'
		48 = 'ECG - 48 hours post-dose'
		;
	invalue time_invalue
		'screen' = 0
		'P1: pre-dose' = 1
		'P1: 2h' = 2 
		'P1: 4h' = 3
		'P1: 6h' = 4
		'P1: 48h' = 5
		'P2: pre-dose' = 6
		'P2: 2h' = 7 
		'P2: 4h' = 8
		'P2: 6h' = 9
		'P2: 48h' = 10
		'post-study' = 11 
		'unscheduled' = .
		;
	value time_value
		0 = 'screen'
		1 = 'P1: pre-dose'
		2 = 'P1: 2h'
		3 = 'P1: 4h'
		4 = 'P1: 6h'
		5 = 'P1: 48h'
		6 = 'P2: pre-dose'
		7 = 'P2: 2h'
		8 = 'P2: 4h'
		9 = 'P2: 6h'
		10 = 'P2: 48h'
		11 = 'post-study' 
		other = .
		;
	invalue FORM_invalue
		'Pre-dose' = 1
		'2 hours post-dose' = 2
		'4 hours post-dose' = 3
		'6 hours post-dose' = 4
		'48 hours post-dose' = 5
		; 
	value FORM_value
		1 = 'Pre-dose'
		2 = '2 hours post-dose'
		3 = '4 hours post-dose'
		4 = '6 hours post-dose'
		5 = '48 hours post-dose'
		; 
	/*
	invalue VSTEST_invalue
		'Weight' = 1
 		'Height' = 2
 		'Body Mass Index' = 3
 		'Body Temperature' = 4
		'Systolic Blood Pressure' = 5
		'Diastolic Blood Pressure' = 6
		'Pulse Rate' = 7
		'Oxygen Saturation' = 8
		'Respiratory Rate' = 9
		;
	value VSTEST_value
		1 = 'Weight'
 		2 = 'Height'
 		3 = 'Body Mass Index'
 		4 = 'Body Temperature'
		5 = 'Systolic Blood Pressure'
		6 = 'Diastolic Blood Pressure'
		7 = 'Pulse Rate'
		8 = 'Oxygen Saturation'
		9 = 'Respiratory Rate'
		;
	invalue EGTEST_invalue
		'Heart Rate' = 1
		'P Wave Axis' = 2
		'P Wave Duration, Aggregate' = 3
		'PR Interval, Aggregate' = 4
		'QRS Duration, Aggregate' = 5
		'QT Interval, Aggregate' = 6
		'QTc, Fredericia' = 7
		'RR Interval, Aggregate ' = 8
	;
	value EGTEST_value
		1 = 'Heart Rate'
		2 = 'P Wave Axis' 
		3 = 'P Wave Duration, Aggregate' 
		4 = 'PR Interval, Aggregate' 
		5 = 'QRS Duration, Aggregate' 
		6 = 'QT Interval, Aggregate'
		7 = 'QTc, Fredericia'
		8 = 'RR Interval, Aggregate '
	;
	*/
	invalue VSSTRESC_invalue
		'N/A' = 0
		'Normal' = 1
		'NCS' = 2
		'CS' = 3
		;
	value VSSTRESC_value
		0 = 'N/A'
	 	1 = 'Normal'
		2 = 'Abnormal, NCS'
		3 = 'Abnormal, CS'
		;
	invalue SUOCCUR_invalue
		'No' = 0
		'Yes' = 1
		;
	value SUOCCUR_value
		0 = 'No'
		1 = 'Yes'
		;
	invalue SUTRT_invalue
		'ALCOHOL' = 1
		'SMOKER' = 2
		'OTHER' = 3
		;
	value SUTRT_value
		1 = 'ALCOHOL'
		2 = 'SMOKER'
		3 = 'OTHER'
		;
	invalue EGSTRESC1_invalue
		'Normal' = 0
		'Abnormal, NCS' = 1
		'Abnormal, CS' = 2
		;
	value EGSTRESC1_value
		0 = 'Normal'
		1 = 'Abnormal, NCS'
		2 = 'Abnormal, CS'
		;
	invalue LBCLSIG_invalue
		'Normal' = 0
		'NCS' = 1
		'CS' = 2
		;
	value LBCLSIG_value
		0 = 'Normal'
		1 = 'Abnormal, NCS'
		2 = 'Abnormal, CS'
		;
	invalue VISIT_invalue
 		'Screening' = 0
		'Screening Visit' = 0
		'Day 1' = 1
		'DAY 1' = 1
 		'Day 2' = 2
		'Day 3' = 3
		'Day 4' = 4
		'Day 5' = 5
		'Day 6' = 6
		'Day 7' = 7
		'Day 7 Visit' = 7
		'Day 15' = 15
		'Day 21 Visit' = 21
		'Week 4' = 28
		'Week 6' = 42
		'Week 6 Visit' = 42
		'Week 10' = 70
		'Week 10/Early Withdrawal Visit' = 70
		'Unscheduled' = .
		;
	value VISIT_value
 		0 = 'Screening'
		1 = 'Day 1'
 		2 = 'Day 2'
		3 = 'Day 3'
		4 = 'Day 4'
		5 = 'Day 5'
		6 = 'Day 6'
		7 = 'Day 7'
		15 = 'Day 15'
		21 = 'Day 21'
		28 = 'Week 4'
		42 = 'Week 6'
		70 = 'Week 10'
		other = .
		;
run;

proc format; 
	%let low='LIGR'; /*pale blue: '#4ED3D4'*/
	%let high='LIGR'; /*pale red: '#D9544D'*/
	/* vital signs*/
	value 	BODTEM 		low-35.5=&low. 
						35.5-37.5='white' 
						37.5-high=&high.;
	value SBP			low-90=&low.
						90-140='white'
						140-high=&high.;
	value DBP			low-60=&low.
						60-90='white'
						90-high=&high.;
	/*
	value	sup_sys 	low-90=&low.
						90-140='white'
						140-high=&high.;
	value	sup_dia 	low-45=&low.
						45-90='white'
						90-high=&high.;
	value	sta_sys 	low-85=&low.
						85-150='white'
						150-high=&high.;
	value	sta_dia 	low-50=&low.
						50-95='white'
						95-high=&high.;
	*/
	value	PULSE 		low-40=&low.
						40-100='white'
						100-high=&high.;
	value 	RESPIR		low-12=&low.
						12-20='white'
						20-high=&high.;
	value	OXYSAT		low-95=&low.
						95-100='white'
						100-high=&high.;
	/* ECG */ 
	value ECG_HR		low-40=&low.
						40-100='white'
						100-high=&high.;
	value ECG_RR		low-600=&low.
						600-1000='white'
						1000-high=&high.;
	value ECG_QRS		low-0=&low.
						0-119='white'
						119-high=&high.;
	value ECG_QTint		low-350=&low.
						350-440='white'
						440-high=&high.;
	value ECG_QTc		low-0=&low.
						0-460='white'
						460-high=&high.;
	value ECG_PR		low-120=&low.
						120-220='white'
						220-high=&high.;
	value ECG_axis		low--30=&low.
						-30-90='white'
						90-high=&high.;
	value ECG_wave 		low-0=&low.  
						0-130='white' /*unknown normal range*/
						130-high=&high.;
	/* GCS */
	value GCS_total		15 = 'white'
						other = &low.;
	value $GCS_eye		'Eye open spontaneously' = 'white'
						other = &low.;
	value $GCS_verbal	'Orientated' = 'white'
						other = &low.;
	value $GCS_motor	'Obeys commands' = 'white'
						other = &low.;
	/* PE */
	value $PEORRES		'' = 'white'
						'.' = 'white'
						'Normal' = 'white'
						'Abnormal, NCS' = 'white'
						'Abnormal, CS' = &high.
						other = &high.;
	/* DV */
	value $DVCAT		'Minor' = 'white'
						'Major' = &high.
						other = &high.; 
	/* PR */ 
	value $PREGPERF		'Yes'='white'
						other = &low.;
	value $PREGORRES	'Negative' = 'white' /* change to negative */ 
						other = &high.;
run; 

/* colour extreme values */ 
%macro color(name=);
	%if &name.=VS %then %do;
	compute 'Body Temperature (°C)'n;
		call define(_col_,'style','style={background=BODTEM.}');
	endcomp;
	compute 'Systolic Blood Pressure (mmHg)'n;
		call define(_col_,'style','style={background=SBP.}');
		/*
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_sys.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_sys.}');
		end;
		*/
	endcomp;
	compute 'Diastolic Blood Pressure (mmHg)'n;
		call define(_col_,'style','style={background=DBP.}');
		/*
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_dia.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_dia.}');
		end;
		*/
	endcomp;
	compute 'Pulse Rate (beats/min)'n;  /* per */
			call define(_col_,'style','style={background=PULSE.}');
	endcomp;
	compute 'Respiratory Rate (beats/min)'n;  /* per */
			call define(_col_,'style','style={background=RESPIR.}');
	endcomp;
	compute 'Oxygen Saturation (%)'n;
			call define(_col_,'style','style={background=OXYSAT.}');
	endcomp;
	%end;
	%if &name.=EG %then %do;
	compute 'Heart Rate (bpm)'n;
		call define(_col_,'style','style={background=ECG_HR.}');
	endcomp;
	compute 'RR Interval, Aggregate'n;
		call define(_col_,'style','style={background=ECG_RR.}');
	endcomp;
	compute 'QRS Duration, Aggregate (msec)'n;
		call define(_col_,'style','style={background=ECG_QRS.}');
	endcomp;
	compute 'QT Interval, Aggregate (msec)'n;
		call define(_col_,'style','style={background=ECG_QTint.}');
	endcomp;
	compute 'QTc, Fredericia (msec)'n;
		call define(_col_,'style','style={background=ECG_QTc.}');
	endcomp;
	compute 'PR Interval, Aggregate (msec)'n;
		call define(_col_,'style','style={background=ECG_PR.}');
	endcomp;
	compute 'P Wave Duration, Aggregate (msec'n;
		call define(_col_,'style','style={background=ECG_wave.}');
	endcomp;
	compute 'P Wave Axis (degrees)'n;
		call define(_col_,'style','style={background=ECG_axis.}');
	endcomp;
	%end;
	%if &name.=GC %then %do;
	compute GCS_TOTAL;
		call define(_col_,'style','style={background=GCS_total.}');
	endcomp;
	compute BESTEYERESPONSE;
		call define(_col_,'style','style={background=$GCS_eye.}');
	endcomp;
	compute BESTVERBALRESPONSE;
		call define(_col_,'style','style={background=$GCS_verbal.}');
	endcomp;
	compute BESTMOTORRESPONSE;
		call define(_col_,'style','style={background=$GCS_motor.}');
	endcomp;
	%end;
	%if &name.=PE %then %do;
	compute PEORRES / character length=50;
		call define(_col_,'style','style={background=$PEORRES.}');
	endcomp;
	%end;
	%if &name.=DV %then %do;
	compute DVCAT / character length=50;
		call define(_col_,'style','style={background=$DVCAT.}');
	endcomp;
	%end;
	%if &name.=PR %then %do;
	compute PREGPERF / character length=50;
		call define(_col_,'style','style={background=$PREGPERF.}');
	endcomp;
	compute PREGORRES / character length=50;
		call define(_col_,'style','style={background=$PREGORRES.}');
	endcomp;
	%end;
%mend color;
/*
Arguments: Choose one of two CDISC abbreviations (either 'VS' or 'EG').
Description: This macro uses colour for values below or above the normal range.
*/

%macro title(type=, label=);
	%let type = %sysfunc(dequote(&type.));
    %if not %symexist(&type._n) %then %do;
		%global &type._n;
        %let &type._n = 0;
    %end;
    %let &type._n = %eval(&&&type._n + 1);
    %let labtitle = %upcase(&type) &&&type._n: %sysfunc(dequote(&label.));
    title "&labtitle";
    ods proclabel "&labtitle";
%mend title;

/******************************************************************************/
/*** Section 4: Analysis ******************************************************/
/******************************************************************************/

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.1: import clinical data  * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc import datafile="&pathRand.\randomisation_list.csv"
		out=random
		dbms=csv;
run;

data random;
	set random;
	if treatment=1 then
		temp ='sustained-release (SR)';
	else if treatment=2 then
		temp='immediate-release (IR)';
	else
		put 'ERROR: invalid value for treatment';
	drop treatment;
	rename temp=treatment;
run;

%prepare;

%let treat_days='Day 1' 'Day 2' 'Day 3' 'Day 4' 'Day 5' 'Day 6' 'Day 7' 'Day 15';
%let post_weeks='Week 4' 'Week 6' 'Week 10';
 
/*
- normal ranges for vital signs (supine/sitting/standing), electro-cardiogram, and haematology
- LB results are always juged NCS or CS (never normal). Do we expect this? (This is different for VS and ECG.)
- data set PE variable PEORRES should have the possible values "Normal", Abnormal, NCS" and "Abnormal, CS" but also has the value "D".
- LB: different units, missing units
- data dictionary?
*/
/*
ods pdf file="&pathOut.\myfile.pdf" style=printer startpage=yes author="Armin Rauschenberger";
*/

options nodate nonumber;
ods escapechar='^';
ods pdf file="&pathOut.\\myfile.pdf" style=printer startpage=no;
ods pdf text="^S={just=c font_size=24pt font_weight=bold} ^10n 5FC HIV-Crypto";
ods pdf text="^S={just=c font_size=24pt} ^1n Tables, Listings, and Figures";
ods pdf text="^S={just=c font_size=14pt} ^10n Armin Rauschenberger";
ods pdf text="^S={just=c font_size=14pt} ^1n %sysfunc(today(), worddate.)";
ods pdf text="^S={just=c font_size=14pt} ^5n ";

proc odstext;
	h1 "Disclaimer";
	p  "^{style [color=red fontweight=bold] Problems in the datasets have not yet been fixed.}";
	p  "^{style [color=red fontweight=bold] Reference ranges and conversion factors have not yet been provided.}";
	p  "^{style [color=red fontweight=bold] The programming code has not yet been double-checked.}";
run;

ods text="Please add text directly to the source code (.sas) and not to the compiled document (.pdf or .docx). Otherwise each update in the data or the code will erase the text.";


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.2: vital signs * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

data VS;
	set VS;
	if VSPOS in (' ','.') then VSPOS='N/A';
	if VSSTRESC in (' ','.') then VSSTRESC='N/A';
run;


%order_levels(code=VS,var=VISIT);
/*%order_levels(code=VS,var=VSTEST);*/
%order_levels(code=VS,var=VSSTRESC);
/*%order_levels(code=VS,var=time);*/
%as_numeric(code=VS,var=VSORRES);
/*%sub_per(code=VS);*/
%add_unit(code=VS);

/* table: vital signs at screening visit by treatment */ 
%tabulate(code=VS,visit="Screening");

/* try report with colour

proc report data=VS;
	where RID=102 and VISIT_='Screening';
    columns RID VISIT VSTEST VSSTRESC_ VSORRES;
    define VSORRES  / display;
    define VSSTRESC_ / display;
    compute VSORRES;
        if VSSTRESC_ = 'Abnormal, NCS' then
            call define(_col_, 'style', 'style=[backgroundcolor=grey color=white]');
		if VSSTRESC_ = 'Abnormal, CS' then
            call define(_col_, 'style', 'style=[backgroundcolor=black color=white]');
    endcomp;
run;


%getvars(code=VS);
%extract_ids_abnormal(code=VS,visit='Screening');
data long;
	set VS;
	if RID=102;
	if VISIT_='Screening';
run; 
proc sort data=long;
	by RID VISIT_;
run;
options validvarname=any;
proc transpose data=long out=wide;
	by RID VISIT_;
	id VSTEST;
	var VSORRES VSSTRESC_;
run;
proc report data=wide;
run;
options validvarname=v7;

end trial */ 

/* listing: abnormal at screening */
%list_abnormal(code=VS,check_visit='Screening',show_visit='Screening' 'Unscheduled');

/* tables: values of and change in vital signs*/ 
%process_table(code=VS,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg)|Pulse Rate (beats/min)|Respiratory Rate (beats/min)|Oxygen Saturation (%)); /* per */

/*table: count of abnormal values */

proc summary data=VS nway;
	where not missing(RID);
	class VSSTRESC VSTEST RID VISIT treatment;
	output out=temp;
run;

proc tabulate data=temp;
	%title(type="listing",label='Count and Percentage of Normal, NCS or CS Abnormal Vital Signs');
	title2 '(by visit, vital sign, and treatment)';
	where not missing(RID);
	class VISIT treatment VSTEST VSSTRESC RID / order=internal;
	table VISIT * VSTEST * VSSTRESC * (n pctn<VSSTRESC>='%'),
		  treatment;
run;

/* listing: abnormal during treatment */ 
%list_abnormal(code=VS,check_visit=&treat_days.,show_visit=&treat_days. &post_weeks.);

/* figures: trajectories of patients with abnormal values */ 
%process_traject(code=VS,check_visit=&treat_days.,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg))

/* figures: mean values and mean change */ 
%process_trend(code=VS,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg)|Pulse Rate (beats/min)) /* per */

/* vital signs post study, by treatment */
%tabulate(code=VS,visit="Week 10");

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.2: electrocardiogram * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%order_levels(code=EG,var=VISIT);
%order_levels(code=EG,var=EGSTRESC1);
/*%order_levels(code=EG,var=EGTEST);*/
%as_numeric(code=EG,var=EGORRES);
/*%sub_per(code=EG);*/
%add_unit(code=EG);

/* table: electrocardiogram, at day 1*/ 
%tabulate(code=EG,visit="Day 1");

/* listing: abnormal EG at day 1*/ 
%list_abnormal(code=EG,check_visit='Day 1',show_visit='Day 1');

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * Subsection 4.3: laboratory* * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*
To discuss with Aljosa: Rows with value but without unit. Consider LBCO? But some rows have no free-text comment. And at least one comment is 10E3/L but should be 10E3/UL.

proc report data=LB;
	where not missing(LBORRES) and missing(LBORRESU) and LBTEST in ('Leucocytes','Magnesium','Neutrophils');
run;

Leucocytes has either LBORRESU equal to 109/L or cells/uL or a free-text comment in LBCO (multiple variants of 10e3/uL).
Magnesium has LBORRESU5 equal to mg/dL or nmol/L, but sometimes there is no unit.
Neutrophils has LBORREESU equal to 109/L or cells/uL, but sometimes there is no unit.
U-Leucocytes always has the unit Leu/uL. However, its values are not always numerical but also +, NEG, N. Once, the value is in the free-text LCBO ("NEGATIVE").
(Similar problems also occur for other variables.)
 */

%order_levels(code=LB,var=VISIT);
%order_levels(code=LB,var=LBCLSIG);
/*%order_levels(code=LB,var=time);*/

/*
semi-quantitative urine analysis (negative, trace, 1/2/3/4+ 
change w.r.t. screening should only be done for numerical (not semi-quantitative values)
*/ 

data LB;
    set LB;
    length type $60;
    if index(FORM,'Clinical Chemistry')>0 then type='Clinical Chemistry';
    else if index(FORM,'Hematology')>0 then type='Hematology';
    else if index(FORM,'Urianalysis')>0 then type='Urianalysis';
    else if index(FORM,'HIV')>0 then type='HIV Test';
    else LBCAT='Other';
	if LBORRES='.' and LBSTNRC='Positive' then LBORRES='Positive';
	else if LBORRES='.' and LBSTNRC='Negative' then LBORRES='Negative';
run;


data LB;
	set LB;
	/*LBORRES_original = LBORRES;*/
	if LBORRES in ('Negative','Positive','N','NEG','TRACE','<1.8','<2.0','>10','1+','2+','3+','4+','+','+++') then do;
		LBORRES_numeric = '';
		LBORRES_ordinal = LBORRES;
	end;
	else do;
		LBORRES_numeric = LBORRES;
		LBORRES_ordinal = '';
	end;
	LBORRES=LBORRES_numeric;
	/*
	drop LBORRES;
	rename LBORRES_numeric = LBORRES;
	*/
run;

%as_numeric(code=LB,var=LBORRES); /* contains values like N, +++, NEG, 1+, TRACE*/ 
%as_numeric(code=LB,var=LBORRES_numeric);

data LB;
	length temp $60;
	set LB;
	temp = coalescec(LBORRESU, LBORRESU2, LBORRESU3, LBORRESU4, LBORRESU5, LBORRESU31);
	drop LBORRESU;
	rename temp=LBORRESU;
run;

data LB;
	set LB;
	if LBTEST = 'Albumin' then do;
		if LBORRESU = 'g/dL' then do;
			LBORRES = 10*LBORRES;
			LBORRESU = 'g/L';
		end;
	end;
	else if LBTEST = 'Creatinine' then do;
		if LBORRESU = 'mg/dL' then do;
			LBORRES = 88.42*LBORRES;
			LBORRESU = 'umol/L';
		end;
	end;
	else if LBTEST = 'Glucose' then do;
		if LBORRESU = 'mg/dL' then do;
			LBORRES = LBORRES/18;
			LBORRESU = 'mmol/L';
		end;
	end;
	else if LBTEST = 'Magnesium' then do;
		if LBORRESU = 'mg/dL' then do;
			LBORRES = 0.4114*LBORRES;
			LBORRESU = 'mmol/L';
		end;
	end;
	else if LBTEST = 'Urea' then do;
		if LBORRESU = 'mg/dL' then do;
			LBORRES = LBORRES/6;
			LBORRESU = 'mmol/L';
		end;
	end;
	else if LBTEST = 'Platelets' then do;
		if LBORRESU = '103/uL' then do;
			/* NB: 10^3/uL = 10^9/L */
			LBORRESU = '109/L';
		end;
	end;
	else if LBTEST = 'Total Bilirubin' then do;
		if LBORRESU = 'mg/dL' then do;
			LBORRES = 17.104*LBORRES;
			LBORRESU = 'umol/L';
		end;
	end;
	else if LBTEST = 'Total Protein' then do;
		if LBORRESU = 'g/dL' then do;
			LBORRES = 10*LBORRES;
			LBORRESU = 'g/L';
		end;
	end;
run;

/*%sub_per(code=LB);*/
%add_unit(code=LB);

%macro process_LB(types=,visits=);
	%local i type j visit;
	%do j = 1 %to %sysfunc(countw(&visits, |));
        %let visit = %scan(&visits, &j, |);
		%do i = 1 %to %sysfunc(countw(&types, |));
  			%let type = %scan(&types, &i, |);
  			%tabulate(code=LB,type="&type",visit="&visit");
		%end;
	%end;
	%do i = 1 %to %sysfunc(countw(&types, |));
		%let type = %scan(&types, &i, |);
		%list_abnormal(code=LB,type="&type",check_visit='Screening',show_visit='Screening' 'Unscheduled');
	%end;
%mend process_LB;

%process_LB(types=Clinical Chemistry|Hematology,visits=Screening|Day 15)

/* urine analysis*/ 


data LB_temp;
	set LB;
	if not missing(LBORRES_numeric) then do;
		LBORRES_both = put(LBORRES_numeric, best12.);
	end;
	else if not missing(LBORRES_ordinal) then do;
		LBORRES_both = LBORRES_ordinal;
	end;
	else do;
		LBORRES_both = '';
	end;
	/*
	drop LBORRES;
	rename temp=LBORRES;
	*/
run;

%list_abnormal(code=LB_temp,type="Urianalysis",check_visit='Screening',show_visit='Screening' 'Unscheduled');


proc tabulate data=LB;
	%title(type="table",label="Urinalysis - numerical variables");
	where type='Urianalysis' and VISIT_='Screening';
	var LBORRES_numeric;
	class treatment VISIT_ LBTEST LBCLSIG;
	table	LBTEST * LBCLSIG * (n pctn<LBCLSIG>='%')
			LBTEST * LBORRES_numeric * (mean std median min max n),
			treatment all='total';
run;

proc tabulate data=LB;
%title(type="table",label="Urinalysis - ordinal variables");
	where type='Urianalysis' and VISIT_='Screening';
	class treatment VISIT_ LBTEST LBCLSIG LBORRES_ordinal;
	table	LBTEST * LBCLSIG * (n pctn<LBCLSIG>='%')
			LBTEST * LBORRES_ordinal * (n pctn<LBORRES_ordinal>='%'),
			treatment all='total';
run;

/* infection tests*/ 

proc tabulate data=LB;
	%title(type="table",label='Infection Tests at Screening Visit');
	where type='HIV Test' and VISIT_='Screening';
	var LBORRES;
	class VISIT_ treatment LBTEST;
	table 	LBTEST * LBORRES * (mean std median min max n),
			treatment all='total';
run;


/*
proc tabulate data=LB;
	%title(type="table",label='Infection Tests at Screening Visit');
	title2 "(summary statistics for numerical variables)";
    where type='HIV Test' and VISIT_='Screening' and LBORRES is not missing;
    var LBORRES;
    class VISIT_ treatment LBTEST;
    table LBTEST * LBORRES * (mean std median min max n),
          treatment all='total';
run;
proc tabulate data=LB;
	%title(type="table",label='Infection Tests at Screening Visit');
	title2 "(counts and percentages for binary variables)";
    where type='HIV Test' and VISIT_='Screening' and LBSTNRC is not missing;
    class VISIT_ treatment LBTEST LBSTNRC;
    table LBTEST * LBSTNRC * (n pctn<LBSTNRC>='%'),
          treatment all='total';
run;
*/

/* Switch to showing those with CS only?*/ 

/* tables: */ 

%process_table(code=LB,tests=Haemoglobin (g/dL)|Leucocytes); /* per */

/* */ 
%process_trend(code=LB,tests=Haemoglobin (g/dL)|Leucocytes); /* per */

/* */ 
%process_traject(code=LB,check_visit=&treat_days.,tests=Haemoglobin (g/dL)|Leucocytes); /* per */


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.XXX: XXX * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc report data=ART;
	%title(type="listing",label='ART initiation');
	*column RID VISIT ARTREGIMEN;
	define RID/order;
run;

proc report data=ARTT;
	%title(type="listing",label='ART treatment');
	column RID ARTSTDAT ART_FIRST_REGIMEN ART_SWITCH;
	define RID/order;
run;

proc report data=CE spanrows;
	%title(type="listing",label='current symptoms');
	column RID VISIT CETERM CEDUR;
	define RID/order;
	define VISIT/order=internal;
run;

proc report data=CM;
	%title(type="listing",label='concomitant medications');
	column RID CMINDC CMTRT;
	define RID/order;
run;

proc report data=DD;
	%title(type="listing",label='death');
	column RID;
run;

proc report data=DI;
	%title(type="listing",label='discharge');
	column RID LPPERF DISCHARGED;
run;

proc report data=DS;
	%title(type="listing",label='disposition milestones');
	column RID VISIT DSDECOD;
	define RID/order;
run;

proc report data=EX;
	%title(type="listing",label='treatment exposure');
	define RID/order;
run;

/* VERIFY HERE WHETHER TREATMENT MATCHES WITH RELATED WITH ARM 1 / ARM 2 IN VARIABLE EXARM!*/ 


/* Glasgow coma score */

%as_numeric(code=GC,var=GCS_TOTAL);

data GC_sub;
  	retain RID VISIT GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE GCS_TOTAL;
	set GC(keep=RID VISIT GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE GCS_TOTAL);
	where GCSPERF="Yes" and GCS_TOTAL < 15;
	drop GCSPERF;
run;

%report(data=GC_sub,title='Glasgow coma scale - patients with a total score below 15',name=GC);


/* lumbar punctures */ 

proc report data=LP;
	%title(type="listing",label='lumbar punctures');
	column RID VISIT LPORRES LPORRESU;
	define RID/order;
run;


/* physical examination */



data PE_sub;
	retain RID VISIT PETESTCD PEORRES PEORRES_SP;
	set PE(keep=RID VISIT PETESTCD PEORRES PEORRES_SP);
	if PEORRES='D' then PEORRES='';
	where not missing(PEORRES) and PEORRES not in ('Normal','','D');
run;

%report(data=PE_sub,title='Physical Examination with Abnormal Results',name=PE);

/* prior medications */ 

proc report data=PM;
	%title(type="listing",label='prior medications');
	column RID CMTRT CMROUTE;
	define RID/order;
run;


/* pregnancy */ 

%order_levels(code=PR,var=VISIT);

data PR_sub;
	retain RID VISIT PREGPERF PREGORRES;
	set PR(keep=RID VISIT PREGPERF PREGORRES);
run;

%report(data=PR_sub,title='Pregnancy Tests and Results',name=PR);


/* palatability */
 
proc report data=QUEST;
	%title(type="listing",label='palatability acceptability');
run;

/* disability */ 

proc report data=RANKIN;
	%title(type="listing",label='disability');
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.2: withdrawals * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

data DS;
	set DS;
	if DSTERM='DISCONTINUED' then withdraw='yes';
	else withdraw='no';
run;

proc tabulate data=DS;
	%title(type="listing",label='withdrawals');
	where VISIT='Post Study';
	class treatment withdraw;
	table withdraw * (n colpctn='%'),
			treatment all='total';
run;

/* TO DO: Add "time of early withdrawal" and "reason of withdrawal". */ 
proc report data=DS;
	%title(type="listing",label='withdrawals');
	where DSTERM='DISCONTINUED';
	column RID treatment;
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.3: ineligibility * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc report data=IE;
run;

proc report data=IE spanrows;
	%title(type="listing",label='ineligible samples');
	where (IECAT='INCLUSION' and IEORRES='No') or (IECAT='EXCLUSION' and IEORRES='Yes');
	column SUBJID IECAT IETEST IEORRES;
	define SUBJID/order;
	define IECAT/order;
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.4: protocol deviations   * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc tabulate data=DV;
	%title(type="table",label="Protocol Deviations");
	title2 "(number and percentage by treatment)";
	class treatment DVCAT;
	table DVCAT * (n rowpctn='%'),
		treatment all="total";
run;

data DV_sub;
	retain RID VISIT FORM DVTERM DVCAT;
	set DV(keep=RID VISIT FORM DVTERM DVCAT);
run;

%report(data=DV_sub,title='Protocol Deviations',title2='(sorted by patient and visit)',name=DV);

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.5: demographics  * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%as_numeric(code=DM,var=vsorres_weight);
%as_numeric(code=DM,var=vsorres_height);
%as_numeric(code=DM,var=vsorres_bmi);
%as_numeric(code=DM,var=age);

data DM;
	set DM;
	weight=vsorres_weight;
	height=vsorres_height;
	bmi=vsorres_bmi;
run;

proc tabulate data=DM;
	%title(type="listing",label='Demographics by Treatment');
	title2 "(top: summary statistics for numerical variables,";
	title3 "bottom: counts and percentages for categorical variables)";
	class treatment sex race;
	var age weight height bmi;
	table 	(age weight height bmi)*(mean median std min max n)
			(sex race)*(n colpctn='%'),
			treatment all='total';
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.6: alcohol and smoking * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%order_levels(code=SU,var=SUOCCUR);
%order_levels(code=SU,var=SUTRT);
%as_numeric(code=SU,var=SUDOSE);

proc tabulate data=SU;
    %title(type="listing",label='alcohol and smoking by sequence');
	class treatment SUTRT SUOCCUR / order=internal;
    var SUDOSE;
    table SUTRT * SUOCCUR * (n pctn<SUOCCUR>='%')
          SUTRT * SUDOSE *(mean std median min max n),
          treatment all='total';
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.7: medical history * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc report data=MH spanrows;
	%title(type="listing",label='medical history');
	where not missing(RID);
	column RID treatment MHTERMPREP MHTERM MHSTDAT MHENDAT MHONGO;
	define RID/order;
	define treatment/order;
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.18: adverse events * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

data AE;
	set AE;
	if AEREL in ('A') then AEREL='';
	if AEREL1 in ('A') then AEREL1='';
run;


proc report data=AE spanrows;
	%title(type="listing",label='adverse events');
	column RID AETERM AESEV AEACN1 AEOUT AEREL AEREL1 treatment;
	define RID/order;
run;

/* VERIFY HERE WHETHER TREATMENT MATCHES WITH RELATED WITH ARM 1 / ARM 2 IN VARIABLES AEREL / AEREL1!*/ 

ods pdf close;


%macro ignore;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.19: pharmacokinetics * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

filename temp "&pathPhar.\0131FRM18_Flucytosine_20230314.csv";
proc import datafile=temp
		out=PK
		dbms=csv;
run;


data PK;
	set PK;
	rename SUBJECTID=RID;
	if SAMPLETIME__HR_='Pre-dose (0)' then SAMPLETIME__HR_=0;
	if CONCENTRATION='BLQ' then CONCENTRATION=0;
	if CONCENTRATION='NS' then CONCENTRATION=.; /* verify this */
	rename SAMPLETIME__HR_=SAMPLETIME;
run;

%add_seq(code=PK);
/*%add_treat(code=PK);*/

%as_numeric(code=PK,var=SAMPLETIME);
%as_numeric(code=PK,var=CONCENTRATION);

/* one separate scatterplot for each sample */

proc sgpanel data=PK noautolegend;
	title 'concentration against time by treatment';
	panelby RID/columns=3 rows=4;
	series x=SAMPLETIME y=CONCENTRATION/group=treatment markers;
run;

/* one common scatterplot for all samples */

proc means data=PK noprint;
	var CONCENTRATION;
	class SAMPLETIME treatment;
	output out=PK_mean mean=mean std=std;
run;

data PK_mean;
	set PK_mean;
	if not missing(SAMPLETIME) and not missing (treatment);
	lower=mean-std;
	upper=mean+std;
run;

proc sgplot data=PK_mean;
	title 'concentration against time by treatment';
	series x=SAMPLETIME y=mean / group=treatment markers markerattrs=(symbol=CircleFilled);
    xaxis label='time';
    yaxis label='concentration';
    keylegend / title='treatment';
	scatter x=SAMPLETIME y=mean/yerrorlower=lower yerrorupper=upper group=treatment;
run;

/* prepare data for WinNonLin */ 

%as_numeric(code=PC,var=PC_DELAY);

data PC;
	set PC;
	if VISIT='Treatment Period 1: 30 hrs PD' then
		period=1;
	else if VISIT='Treatment Period 2: 30 hrs PD' then
		period=2;
	if PC_SAMPLING_TIME='Pre-dose' then
		SAMPLETIME=0;
	else if PC_SAMPLING_TIME='0,5' then
		SAMPLETIME=0.5;
	else
	SAMPLETIME=input(PC_SAMPLING_TIME,best32.);
run;

data PK;
	set PK;
	where not missing(CONCENTRATION);
run;

data merged;
	merge PC(in=a) PK(in=b);
	by RID period SAMPLETIME;
run;

data temp;
	set merged;
	time = SAMPLETIME - PC_DELAY/60; /* double-check unit and sign in R */
	conc = CONCENTRATION;
	keep RID period treatment time conc seqence;
run;

%let version=2024-01-03_T09-45; /* Adapt this line (see below) */ 

proc export data=temp
	outfile="&pathOut.\concentration-data_&version..csv"
	dbms=csv
	replace;
run;

%put Note: Execute intermediate analysis in Phoenix WinNonlin! See details in SAS file.;

/*
1. 	Run the SAS code above here (i.e., ending with proc export),
	which exports the file "concentration-data_XXX.csv" to Phoenix WinNonlin.

	NB: After choosing a meaningful version identififier (e.g., current date),
	define this identifier some lines above ("%let version=XXX;"),
	and use this identifier below ("_XXX.csv").

2. 	Phoenix WinNonlin:

	- 	Import data set: Click on 'file' (in the menu), click on 'import', select "concentration-data_XXX.csv", click on 'open', click on 'finish'.
		You should now see a table with the columns RID, seqence, period, treatment, time and conc.

	- 	Perform analysis: Click on 'send to' (in the menu), click on 'NonCompartmental Analysis', click on 'NCA'.
		In the mappings, select 'sort' for the columns RID, seqence, period and treatment,
		select 'time' for time, and select 'concentration' for conc.
		In the options, select the calculation method 'linear up - log down'.
		Execute the workflow by clicking on the green arrow (below the menu).

	- 	Export data set: Go to 'results - output data - final parameters pivoted', right-click 'final parameters pivoded',
		select export, and save as "final-parameters-pivoted_XXX.csv"

3. 	Run the SAS code below here (i.e., starting with proc import),
	which imports the file "final-parameters-pivoted_XXX.csv" from Phoenix WinNonlin.
*/

filename temp "&pathOut.\final-parameters-pivoted_&version..csv";
proc import datafile=temp
	out=PKpars
	dbms=csv;
run;

data PKpars;
	set PKpars;
	if seqence=1 then
        treat='1 (AB)';
    else if seqence=2 then
        treat='2 (BA)';
    else
        treat='';
run;

data PKpars;
 	set PKpars;
	logCmax = log(Cmax);
	logAUClast = log(AUClast); /* Note difference between AUClast (last positive measurement) and AUCall (last measurement) */
	logAUCinf = log(AUCINF_obs); 
run;

/* mixed model */

%mixmod(outcome=logCmax);
%mixmod(outcome=logAUClast);
%mixmod(outcome=logAUCinf);

%mend ignore;


/* ---------------------- */
/* --- PHASE II STUDY --- */
/* ---------------------- */

/* Mann-Whitney U test */

/*
proc npar1way data=PKpars wilcoxon;
	class treat;
	var Cmax Tmax Lambda_z;
run;
*/

/* ------------- */
/* --- NOTES --- */
/* ------------- */

/*
Things to do:

- mixed models: combine tables
- vital signs: solve date/time formatting
- security analysis
- integration with WinNonlin
- use vertical column labels for wide tables

Consider computing PK parameters in SAS:
- https://www.lexjansen.com/pharmasug-cn/2019/SP/Pharmasug-China-2019-SP63.pdf
- https://www.lexjansen.com/pharmasug/2005/StatisticsPharmacokinetics/sp07.pdf
- https://www.pharmasug.org/proceedings/2023/SA/PharmaSUG-2023-SA-284.pdf

Consider using WinNonLin with SAS:
- https://www.lexjansen.com/pharmasug/2001/Proceed/Posters/P06_russell.pdf

Saving output to PDF or RTF:

ods pdf file="&pathOut.\myfile.pdf" style=journal startpage=no;
SOME CODE
ods pdf close;

Exporting tables to LaTeX:

ods tagsets.TablesOnlyLaTeX file="&pathOut./table_example.tex" stylesheet="pathOut./sas.sty"(url="sas");
SOME CODE
ods tagsets.TablesOnlyLaTeX close;
*/ 

/*
integration of WinNonLin and SAS:

- invoke system command from SAS:
  X <'command'>;

- run WinNonLin from command line:
  https://onlinehelp.certara.com/phoenix/8.2/topics/nlmecliusage.htm

This code does not work:

X<'cd C:\Program Files\R\R-4.3.1\bin'>
X<'R'>
X<'x <- rnorm(100)'>
X<'save(x=x,file="P:\\temporary.RData")'>

Consider running a script (i.e., save code in file, then source this file in R).

%let PhoenixPath = "C:\Program Files (x86)\Certara\Phoenix\application";
%let PhoenixCommand = 

X<'"C:\Program Files\R\R-4.3.1\bin\Rscript.exe" C:\Users\arauschenberger\Desktop\Crypto-HIV\trial.R'>

%let RCommand = "C:\Program Files\R\R-4.3.1\bin\Rscript.exe" "C:\Users\arauschenberger\Desktop\Crypto-HIV\trial.R";
x "&RCommand";

Run everything with a single script from the command line (first SAS, then WinNonLin, then SAS, then LaTeX)?

Start-Process -FilePath "C:\Program Files (x86)\Certara\Phoenix\application\phoenix.exe"
*/


/* vital signs - trajectory */

/* time formatting (keep this code)

data VS;
	set VS;
	temp = input(VSDAT, ddmmyy10.);
	date = put(temp, yymmdd10.);
	VSDTC = catx("T",date,VSTIM);
	/* datetime = input(VSDTC, E8601DT.);
	drop temp;
run;

data VS;
	set VS;
	before = lag(time);
	if time='other' then do;
		time = before || " - us";
	end;
	drop before;
run;

data VS;
	set VS;
	if length(datetime)<10 then do;
		date_time=.;
	end;
	else do;
		date_time = input(datetime, E8601DT.);
	end;
	format date_time E8601DT.;
run;

%macro plotvs(test);
	data temp;
		set VS;
		where VSTEST=&test. and VSPOS='Supine';
		if RID in (&ids_abnormal.);
	run;
	proc sort data=temp;
		by VSDTC RID;
	run;
	proc sgplot data=temp;
		series x=VSDTC y=VSORRES / group=RID markers datalabel=time; 
    	title "Supine &test.";
    	xaxis label='time';
    	yaxis label='value';
   		keylegend / title='RID';
	run;
%mend plotvs;

%plotvs('Systolic Blood Pressure');
%plotvs('Diastolic Blood Pressure');
*/

