
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

proc datasets library=work kill;
run;
dm 'odsresults; clear';
dm "log; clear; ";
options nosource;
options nonotes;

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
%macro import(path,code);
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
%macro add_rid(code); 
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
%macro sort_rid(code);
	proc sort data=&code;
		by RID;
	run;
%mend sort_rid;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Sorts the dataset 'code' by the random identifier (RID).
*/

/* add random info */
%macro add_seq(code);
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
   %let code = AE ART ARTT CE CM DD DI DM DS DV EG EX GC IE LB LP MH PE PM PR QUEST RANKIN VS; /* Also add files without code! */
   %do i = 1 %to %sysfunc(countw(&code));
      %import(&pathClin,%scan(&code,&i));
	  %add_rid(%scan(&code,&i));
	  %sort_rid(%scan(&code,&i));
	  %add_seq(%scan(&code,&i));
   %end;
%mend prepare;
/*
Arguments: -
Note: Loops through a list of abbreviations (e.g., 'code = VS DM' for vital signs and demographics).
Description: Prepares the datasets by importing the datasets, adding the random identifiers,
sorting the datasets by random identifiers and adding information on the treatment sequence.
*/

/* convert character to numeric */
%macro asnumeric(code,var);
data &code;
	set &code;
	temp = input(&var,best.);
	drop &var;
	rename temp=&var;
run;
%mend asnumeric;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs)
and a variable name (e.g., 'var=vsorres_weight').
Description: Converts character variable to numeric.
*/

/* derive treatment period */ 
%macro add_period(code);
	data &code.;
		set &code.;
		if VISIT in ('Treatment Period 1: 30 hrs PD','Unscheduled Treatment Period 1') then period='1';
		else if VISIT in ('Treatment Period 2: 30 hrs PD','Unscheduled Treatment Period 2') then period='2';
		else period = '';
	run;
%mend add_period;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Uses the variable 'VISIT' to create the variable 'period'.
*/

/* derive treatment */ 
%macro add_treat(code);
	data &code.;
		set &code.;
    	if period='1' and seq='1 (AB)' then treat='A';
		else if period='1' and seq='2 (BA)' then treat='B';
		else if period='2' and seq='1 (AB)' then treat='B';
		else if period='2' and seq='2 (BA)' then treat='A';
		else treat = '';
	run;
%mend add_treat;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Uses the variable for the period (1 or 2)
and the variable for the treatment sequence (AB or BA)
to create the variable for the treatment (A or B).
*/

/* re-order category levels */
%macro ordervar(code,var);
data &code.;
	set &code.;
	temp = input(&var.,&var._invalue.);
	&var._ = put(temp,&var._value.);
	format temp &var._value.;
	drop &var.;
	rename temp=&var.;
run;
%mend ordervar;
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

/* define variable names TEST and SCORE */ 
%macro getvars(code);
	%global var_test state_by var_score var_judge;
	%if &code.=VS %then %do;
		%let var_test=VSTEST_; /* was VSTESTCD*/
		%let state_by=RID VISIT_ VSPOS;
		%let var_judge=VSSTRESC_;
		%let var_score=VSORRES;
	%end;
	%else %if &code.=EG %then %do;
		%let var_test=EGTEST;
		%let state_by=RID VISIT_;
		%let var_judge=EGSTRESC1_;
		%let var_score=EGORRES;
	%end;
	%else %if &code.=LB %then %do;
		%let var_test=LBTEST;
		%let state_by=RID VISIT_;
		%let var_judge=LBLSIG;
		%let var_score=LBORRES;
	%end;
	%else %do;
		%put ERROR;
	%end;
	%put var_test=&var_test.;
	%put state_by=&state_by.;
	%put var_score=&var_score.;
	%put var_judge=&var_judge.;
%mend getvars;


/* find patients with abnormal results */ 
%macro listncs(code,visit);
	%global ids_ncs;
	/*
	%if &code.=VS %then %do;
		%let var_test=VSSTRESC_;
	%end;
	%else %if &code.=EG %then %do;
		%let var_test=EGSTRESC1_;
	%end;
	%else %if &code.=LB %then %do;
		%let var_test=LBLSIG;
	%end;
	%else %do;
		%put ERROR;
	%end;
	*/
	%getvars(&code.);
    data temp;
        set &code.;
        where VISIT_ in (&visit.) and &var_judge. in ('NCS','CS','Abnormal, NCS','Abnormal, CS') and not missing(RID); /* use numerical values */ 
    run;
    proc sql noprint;
        select distinct RID
        into :ids_ncs separated by ','
        from temp;
    quit;
	%let ids_ncs=&ids_ncs.;
	%put ids_ncs=&ids_ncs.;
%mend listncs;
/*
Arguments: Expects one of two possible CDISC abbreviations
(either 'code=VS' for vital signs or 'code=EG' for electroencephalography),
and one or more visits (e.g., "visit='Screening Visit' 'Post-Study Visit'").
Description: Identifies patients with abnormal results at these visits
and saves their randomisation identifers in the macro variable 'ids_ncs'.
*/

/* show results for some patients */ 
%macro showncs(code,visit);
	/*
	%if &code.=VS %then %do;
		%let var_test=VSTESTCD;
		%let state_by=RID VISIT_ VSPOS;
		%let var_score=VSORRES;
	%end;
	%else %if &code.=EG %then %do;
		%let var_test=EGTEST;
		%let state_by=RID VISIT_;
		%let var_score=EGORRES;
	%end;
	%else %if &code.=LB %then %do;
		%let var_test=LBTEST;
		%let state_by=RID VISIT_;
		%let var_score=LBORRES;
	%end;
	%else %do;
		%put ERROR;
	%end;
	*/
	%getvars(&code.);
	data long;
		set &code.;
		if RID in (&ids_ncs.);
		if VISIT_ in (&visit.);
	run; 
	proc sort data=long;
		by &state_by.;
	run;
	proc transpose data=long out=wide;
		by &state_by.;
		id &var_test.;
		var &var_score.;
	run;
%mend;
/*
Arguments: Expects one of two possible CDISC abbreviations (either 'code=VS' or 'code=EG'),
and one or more visits (e.g., visit='Screening Visit' 'Unscheduled Screening').
*/

/* report with colour for extreme values */ 
%macro report(data,title,name=none,temp='TRUE');
	proc report data=&data. spanrows;
		%color(name=&name.,temp=&temp.);
		define RID / order order=internal;
		define VISIT_ / order order=internal;
		/*%if &name.=EG %then %do;
			define PAGENAME / order order=internal;
		%end;*/
		define _NAME_/noprint;
		title &title.;
	run;
%mend;
/*
Arguments: Expects  a dataset (e.g., 'data=mydata') and a title for the output (e.g., "title='a title'").
The first optional argument can be changed from 'name=none' (default) to 'name=EG' to also order by PAGENAME.
And the second optional argument 'temp=TRUE' (default) to 'name=FALSE' to suppress the formatting for temperature.
Description: Adds colour for extreme values (see format section). Defines order of category levels.
*/

/* report patients with abnormal values*/ 
%macro abnormal(code,check_visit,show_visit,temp='TRUE');
	%listncs(code=&code.,visit=&check_visit.);
	%showncs(code=&code.,visit=&show_visit.);
	%report(data=wide,title="&code. data at &show_visit. (for those abnormal at &check_visit.)",name=&code.,temp=&temp.);
%mend abnormal;
/*
Arguments: Expects CDISC abbreviation (either 'code=VS' or 'code=EG'),
the visit(s) to be checked for abnormal results (e.g., "check_visit='Screening Visit'"),
and the visit(s) to be shown (e.g., "show_visit='Unscheduled Screening'").
The optional argument can changed from "temp='TRUE'" (default) to "temp='FALSE'"
to omit the formatting for the variable temperature (if available).
Description: Identifies patients with abnormal results at one or more visits ('check_visit')
and shows the results for these patients at one or more visits ('show_visit').
*/ 

proc report data=VS;
run;

/* summarise vital signs - values */ 
%macro tabval(code,test,position);
	%getvars(&code.);
	proc tabulate data=&code.;
		%if &code.=VS %then %do;
			where VSPOS=&position. and &var_test.=&test.;
			class &var_test. VSPOS VISIT treat / order=internal;
		%end;
		%else %if &code.=LB %then %do;
			where &var_test.=&test.;
			class &var_test. VISIT treat / order=internal;		
		%end;
		%else %do;
			%put ERROR;
		%end;
		/*
		where VSPOS=&position. and &var_test.=&test.;
		class &var_test. VSPOS VISIT treat / order=internal;
		*/
		var &var_score.; /*was VSORRES*/
		table 	VISIT * &var_score. * (mean std median min max n), /*was VSORRES*/
			treat;
		title &position. ' ' &test. ' - values';
	run;
%mend tabval;
/*
Arguments: Expects a test ('Systolic Blood Pressure', 'Diastolic Blood Pressure' or 'Pulse Rate')
and a position (default 'Supine' or 'Standing').
Description: Summarises measurements for each time point (rows) and treatment (columns).
*/ 

/* calculate change */
%macro calcdiff(code,test,position);
	data temp;
		set &code.;
		where VSTEST_=&test. and VSPOS=&position. and not missing(RID);
	run;
	data temp;
  		do until(last.RID);
     		set temp;
     		by RID;
     		if treat = 'immediate-release (IR)' then do;
        		if baseA = . then baseA = VSORRES;
        		diff = VSORRES - baseA;
     		end;
			drop baseA;
     		else if treat = 'sustained-release (SR)' then do;
        		if baseB = . then baseB = VSORRES;
				diff = VSORRES - baseB;
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
%macro tabdiff(test,position);
proc tabulate data=temp;
	class VISIT treat / order=internal;
	var diff;
	table 	VISIT * diff * (mean std median min max n),
			treat;
	title &position. '  ' &test. ' - change';
run;
%mend;
/*
Arguments: Expects a test ('Systolic Blood Pressure', 'Diastolic Blood Pressure' or 'Pulse Rate')
and a position ('Supine' or 'Standing').
Description: Summarises change with respect to pre-dose for each time point (rows) and treatment (columns).
*/ 

/* plot trajectories of vital signs */
%macro plotind(test,position);
	data temp;
		set VS;
		where VSTEST_=&test. and VSPOS=&position.;
		if RID in (&ids_ncs.);
	run;
	proc sort data=temp;
		by RID; /*included VSDTC*/ 
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
		series x=visit y=VSORRES / group=RID markers;
    	title &position. ' ' &test.;
    	xaxis label='time'; 
    	yaxis label='value';
   		keylegend / title='RID';
		%if &position.='Supine' and &test.='Systolic Blood Pressure' %then %do;
			refline 90 140 / axis=y lineattrs=(thickness=2);
		%end;
		%if &position.='Supine' and &test.='Diastolic Blood Pressure' %then %do;
			refline 45 90 / axis=y lineattrs=(thickness=2);
		%end;
		refline 0 1 2 3 4 5 6 7 8 9 10 11 / axis=x lineattrs=(thickness=0.5 pattern=dash);
	run;
%mend plotind;
/*
Arguments: Expects test 'Systolic Blood Pressure' or 'Diastolic Blood Pressure'
and position 'Supine' (default) or 'Standing'.
Description: Extracts data from the dataset 'VS'  for the individuals in 'ids_ncs',
the position 'Supine' and the chosen test.
Sorts the extracted data by the sample identifier and the time point.
Replaces missing visit names by the visit name of the lagged time point.
Plots the measurements against the visit names, with one line for each patient.
*/

/* plot mean value or mean change */
%macro plot_internal(title);
	data VS_means;
		set VS_means;
		where not missing(RID);
	run;
	proc sgplot data=VS_means;
		series x=visit y=mean / group=treat markers markerattrs=(symbol=CircleFilled);
    	title &title.;
    	xaxis label='time';
    	yaxis label='value';
    	keylegend / title='treatment';
		highlow x=visit low=lclm high=uclm / group=treat;
		scatter x=visit y=mean/yerrorlower=lclm yerrorupper=uclm group=treat;
	run;
%mend plot_internal;
%macro plot_mean_value(test,position);
	proc means data=VS mean clm alpha=0.05 noprint;
		where VSTEST_=&test. and VSPOS=&position.;
		var VSORRES;
		class treat visit;
		output out=VS_means mean=mean lclm=lclm uclm=uclm;
	run;
	%plot_internal(title='Mean ' &position. ' ' &test.);
%mend plot_mean_value;
%macro plot_mean_change(test,position);
	%calcdiff(&test.);
	proc means data=temp mean clm alpha=0.05 noprint;
		where VSTEST_=&test. and VSPOS=&position.;
		var diff;
		class treat visit;
		output out=VS_means mean=mean lclm=lclm uclm=uclm;
	run;
	%plot_internal(title='Mean change in ' &position. ' ' &test.);
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

/* perform mixed modelling */ 
%macro mixmod(outcome,data=PKpars,class=rid treat period treat,fixed=treat period treat,random=rid(treat),lsmeans=treat,alpha=0.10);
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
	invalue VSSTRESC_invalue
		'Normal' = 0
		'NCS' = 1
		'CS' = 2
		;
	value VSSTRESC_value
	 	0 = 'Normal'
		1 = 'NCS'
		2 = 'CS'
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
	invalue VISIT_invalue
 		'Screening' = 0
		'Day 1' = 1
 		'Day 2' = 2
		'Day 3' = 3
		'Day 4' = 4
		'Day 5' = 5
		'Day 6' = 6
		'Day 7' = 7
		'Day 15' = 8
		'Week 4' = 9
		'Week 6' = 10
		'Week 10' = 11
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
		8 = 'Day 15'
		9 = 'Week 4'
		10 = 'Week 6'
		11 = 'Week 10'
		other = .
		;
run;

proc format; 
	%let low='LIGR'; /*pale blue: '#4ED3D4'*/
	%let high='LIGR'; /*pale red: '#D9544D'*/
	/* vital signs*/
	value 	temp 		low-35.5=&low. 
						35.5-37.5='white' 
						37.5-high=&high.;
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
	value ECG_QRS		low-0=&low.
						0-119='white'
						119-high=&high.;
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
run; 

/* colour extreme values */ 
%macro color(name,temp='TRUE');
	%if &name.=VS %then %do;
		%if &temp.='TRUE' %then %do;
			compute Temperature;
				call define(_col_,'style','style={background=temp.}');
			endcomp;
		%end;
	compute SYSBP;
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_sys.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_sys.}');
		end;
	endcomp;
	compute DIABP;
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_dia.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_dia.}');
		end;
	endcomp;
	compute PULSE;
			call define(_col_,'style','style={background=PULSE.}');
	endcomp;
	compute RESPIR;
			call define(_col_,'style','style={background=RESPIR.}');
	endcomp;
	compute OXYSAT;
			call define(_col_,'style','style={background=OXYSAT.}');
	endcomp;
	%end;
	%if &name.=EG %then %do;
	compute Heart_Rate;
		call define(_col_,'style','style={background=ECG_HR.}');
	endcomp;
	compute QRS_Duration__Aggregate;
		call define(_col_,'style','style={background=ECG_QRS.}');
	endcomp;
	compute PR_Interval__Aggregate;
		call define(_col_,'style','style={background=ECG_PR.}');
	endcomp;
	compute P_Wave_Axis;
		call define(_col_,'style','style={background=ECG_axis.}');
	endcomp;
	compute P_Wave_Duration__Aggregate;
		call define(_col_,'style','style={background=ECG_wave.}');
	endcomp;
	%end;
	%if &name.=GC %then %do;
	compute GCS_TOTAL;
		call define(_col_,'style','style={background=GCS_total.}');
	endcomp;
	compute BESTEYERESPONSE;
		call define(_col_,'style','style={background=GCS_eye.}');
	endcomp;
	compute BESTVERBALRESPONSE;
		call define(_col_,'style','style={background=GCS_verbal.}');
	endcomp;
	compute BESTMOTORRESPONSE;
		call define(_col_,'style','style={background=GCS_motor.}');
	endcomp;
	%end;
%mend color;
/*
Arguments: Choose one of two CDISC abbreviations (either 'VS' or 'EG').
Description: This macro uses colour for values below or above the normal range.
*/

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
		treat='sustained-release (SR)';
	else
		treat='immediate-release (IR)';
run;

%prepare;


/*
Comments on dummy data:
- SUBJD=1009 at VISIT="Screening": PULSE=58 (inside normal range) but VSSTRESC="NCS".
- one abnormal vital sign does not make 

*/


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.2: vital signs at screening  * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%ordervar(code=VS,var=VISIT); /*requires accessing label with VISIT_ below*/
%ordervar(code=VS,var=VSTEST);
%ordervar(code=VS,var=VSSTRESC);
/*%ordervar(code=VS,var=VSTEST);*/
/*%ordervar(code=VS,var=FORM); does not exist */ 
%asnumeric(code=VS,var=VSORRES);

data VS;
	set VS;
	if VSPOS in (' ','.') then VSPOS='N/A';
run;

proc tabulate data=VS;
	title 'vital signs at screening by treatment';
	where VISIT_='Screening';
	class treat VSPOS VSTESTCD VSSTRESC / order=internal;
	var VSORRES;
	table	VSPOS * VSTESTCD * VSSTRESC * (n pctn<VSSTRESC>='%')
			VSPOS * VSTESTCD * VSORRES * (mean std median min max n),
			treat all='both';
run;

/* vital signs - listing of abnormal at screening */
%abnormal(code=VS,check_visit='Screening',show_visit='Screening' 'Unscheduled Screening');

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.11: vital signs by time and treatment  * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%tabval(code=VS,test='Systolic Blood Pressure',position='Sitting');
%calcdiff(code=VS,test='Systolic Blood Pressure',position='Sitting');
%tabdiff(test='Systolic Blood Pressure');
/* combine calcdiff and tabdiff in single macro!*/ 

%tabval(code=VS,test='Diastolic Blood Pressure',position='Sitting');
%calcdiff(code=VS,test='Diastolic Blood Pressure',position='Sitting');
%tabdiff(test='Diastolic Blood Pressure');

%tabval(code=VS,test='Pulse Rate',position='Sitting');
%calcdiff(code=VS,test='Pulse Rate',position='Sitting');
%tabdiff(test='Pulse Rate');

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.12: vital signs - normal/abnormal by time and treatment  * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*
proc summary data=VS nway;
	where not missing(RID);
	class VSSTRESC RID VISIT treat;
	output out=temp;
run;

proc report data=VS;
run;

proc tabulate data=temp;
	title 'vital signs normal/abnormal by treatment and time';
	class VISIT treat VSSTRESC RID / order=internal;
	table VISIT * VSSTRESC * (n pctn<VSSTRESC>='%'),
		  treat;
run;
*/

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.13: vital signs - abnormal during treatment  * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

data long;
	set VS;
	where VSSTRESC_ ne 'Normal' and not missing(RID) and VISIT_ in ('Day 1', 'Day 2', 'Day 3', 'Day 6', 'Day 7', 'Day 15');
	if VSTEST_ = 'Pulse Rate' then VSTEST_ = 'PULSE';
  	else if VSTEST_ = 'Body Temperature' then VSTEST_ = 'TEMP';
	else if VSTEST_ = 'Respiratory Rate' then VSTEST_= 'RESPIR';
	else if VSTEST_ = 'Diastolic Blood Pressure' then VSTEST_ = 'DIAPB';
	else if VSTEST_ = 'Systolic Blood Pressure' then VSTEST_ = 'SYSBP';
	else if VSTEST_ = 'Oxygen Saturation' then VSTEST_ = 'OXYGEN';
run;

proc report data=long;
run;

proc sort data=long;
	by RID treat VISIT VSPOS;
run;

proc transpose data=long out=wide;
	by RID treat VISIT VSPOS;
	id VSTEST_;
	var VSORRES;
run;

%report(data=wide,title='patients with abnormal vital signs - scheduled visits',name=VS,temp='FALSE');

/*
%abnormal(code=VS,check_visit='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD',show_visit='Unscheduled Treatment Period 1' 'Unscheduled Treatment Period 2',temp='FALSE');
*/

/*
compact alternative for the three blocks and two macro calls above:
%let check_visit='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD';
%let show_visit='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD' 'Unscheduled Treatment Period 1' 'Unscheduled Treatment Period 2';
%abnormal(code=VS,check_visit=&check_visit.,show_visit=&show_visit.);
*/

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.14: plot vital signs for abnormal  * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

data VS;
	set VS;
	length time $40;
	if VISIT='Screening' then time='screen';
	else if FORM_='Pre-dose' then time=cat('P',period,': pre-dose');
	else if FORM_='2 hours post-dose' then time=cat('P',period,': 2h');
	else if FORM_='4 hours post-dose' then time=cat('P',period,': 4h');
	else if FORM_='6 hours post-dose' then time=cat('P',period,': 6h');
	else if FORM_='48 hours post-dose' then time=cat('P',period,': 48h');
	else if VISIT='Post Study' then time='post-study';
	else if VISIT in ('Unscheduled Treatment Period 1','Unscheduled Treatment Period 2','Unscheduled Screening') then time='unscheduled';
run;
%ordervar(code=VS,var=time);

%plotind(test='Systolic Blood Pressure',position='Sitting');
%plotind(test='Diastolic Blood Pressure',position='Sitting');

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.15: vital signs - mean values and mean change  * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%plot_mean_value(test='Systolic Blood Pressure',position='Sitting');
%plot_mean_change(test='Systolic Blood Pressure',position='Sitting');

/*
%plot_mean_value(test='Diastolic Blood Pressure');
%plot_mean_change(test='Diastolic Blood Pressure');

%plot_mean_value(test='Pulse Rate');
%plot_mean_change(test='Pulse Rate');
*/

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.16: vital signs - post study * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc tabulate data=VS;
	title 'vital signs at post study by treatment';
	where VISIT_='Week 10';
	class treat VISIT_ VSPOS VSTEST VSSTRESC;
	var VSORRES;
	table	VSPOS * VSTEST * VSSTRESC * (n pctn<VSSTRESC>='%')
			VSPOS * VSTEST * VSORRES * (mean std median min max n),
			treat all='both';
run;

/* vital signs - overall change */

data long;
	set VS;
	where VISIT_ in ('Screening','Week 10') and VSPOS='Sitting' and not missing(RID);
run;

proc sort data=long;
	by RID VSTEST;
run;

proc transpose data=long out=wide;
	by RID VSTEST treat;
	id VISIT;
	var VSORRES;
run;

data wide;
	set wide;
	diff = Week_10 - Screening;
run;

proc tabulate data=wide;
	title 'change in vital signs from screening to post study by sequence';
	class treat RID VSTEST / order=internal;
	var diff;
	table VSTEST * diff * (mean std median min max n), treat;
run;





/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.9: electrocardiogram at screening* * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*%ordervar(code=EG,var=VISIT);*/
%ordervar(code=EG,var=EGSTRESC1);
%asnumeric(code=EG,var=EGORRES);

/* The following data statement creates the variable 'measure = test (unit)'. */
data EG;
	set EG;
	length measure $40;
	VISIT_ = VISIT;
	if missing(EGORRESU) then measure = EGTEST;
	else measure = cat(EGTEST,' (',EGORRESU,')');
run;

proc tabulate data=EG;
	title 'ECG at DAY 1 by treatment';
	where VISIT='DAY 1';
	class treat measure EGSTRESC1;
	var EGORRES;
	table 	measure * EGSTRESC1 * (n pctn<EGSTRESC1>='%')
			measure * EGORRES * (mean std median min max n),
			treat all='both';
run;

/* ECG - listing of abnormal at screening */ 
%abnormal(code=EG,check_visit='DAY 1',show_visit='DAY 1');



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * *  laboratory * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%prepare;

%ordervar(code=LB,var=VISIT);
%asnumeric(code=LB,var=LBORRES);

proc report data=LB;
	title 'laboratory';
run;

proc tabulate data=LB;
	title 'laboratory at screening by treatment';
	where VISIT_='Screening';
	class treat LBTEST LBCLSIG;
	var LBORRES;
	table	LBTEST * LBCLSIG * (n pctn<LBCLSIG>='%')
			LBTEST * LBORRES * (mean std median min max n),
			treat all='both';
run;


/* vital signs - listing of abnormal at screening */

%abnormal(code=LB,check_visit='Screening',show_visit='Screening' 'Unscheduled Screening');

/*here*/
%tabval(code=LB,test='Haemoglobin',position='');
%calcdiff(code=LB,test='Haemoglobin',position='');
%tabdiff(test='Systolic Blood Pressure');





/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.XXX: XXX * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc report data=ART;
	title 'ART initiation';
	*column RID VISIT ARTREGIMEN;
	define RID/order;
run;

proc report data=ARTT;
	title 'ART treatment';
	column RID ARTSTDAT ART_FIRST_REGIMEN ART_SWITCH;
	define RID/order;
run;

proc report data=CE spanrows;
	title 'current symptoms';
	column RID VISIT CETERM CEDUR;
	define RID/order;
	define VISIT/order=internal;
run;

proc report data=CM;
	title 'concomitant medications';
	column RID CMINDC CMTRT;
	define RID/order;
run;

proc report data=DD;
	title 'death';
	column RID;
run;

proc report data=DI;
	title 'discharge';
	column RID LPPERF DISCHARGED;
run;

proc report data=DS;
	title 'disposition milestones';
	column RID VISIT DSDECOD;
	define RID/order;
run;

proc report data=EX;
	title 'treatment exposure';
	define RID/order;
run;

/* only show patients with GCS<15 ? */
/* then add eye verbal and motor*/

%asnumeric(code=GC,var=GCS_TOTAL);

data GC_sub;
	set GC(keep=RID VISIT GCSPERF GCS_TOTAL BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE);
	where GCSPERF="Yes" and GCS_TOTAL < 15;
	eye = BESTEYERESPONSE;
	verbal = BESTVERBALRESPONSE;
	motor = BESTMOTORRESPONSE;
	drop GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE;
run;

%report(data=GC_sub,title='Glasgow coma scale',name=GC,temp='FALSE');

proc report data=GC;
	title 'Glasgow coma score';
	title2 'details: asdfdf';
	where GCSPERF="Yes" and GCS_TOTAL < 15;
	columns RID VISIT eye verbal motor GCS_TOTAL;
	define RID/order;
	define VISIT/order=internal;
run;




proc report data=LP;
	title 'lumbar punctures';
	column RID VISIT LPORRES LPORRESU;
	define RID/order;
run;


proc report data=PE;
	title 'physical examination';
	where PEORRES='Abnormal, CS';
	column RID VISIT PETESTCD PEORRES PEORRES_SP;
	define RID/order;
run;

proc report data=PM;
	title 'prior medications';
	column RID CMTRT CMROUTE;
	define RID/order;
run;

proc report data=PR;
	title 'pregnancy';
run;

proc report data=QUEST;
	title 'palatability acceptability';
run;

proc report data=RANKIN;
	title 'disability';
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
	title 'withdrawals';
	where VISIT='Post Study';
	class treat withdraw;
	table withdraw * (n colpctn='%'),
			treat all='both';
run;

/* TO DO: Add "time of early withdrawal" and "reason of withdrawal". */ 
proc report data=DS;
	title 'withdrawals';
	where DSTERM='DISCONTINUED';
	column RID treat;
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.3: ineligibility * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc report data=IE;
run;

proc report data=IE spanrows;
	title 'ineligible samples';
	where (IECAT='INCLUSION' and IEORRES='No') or (IECAT='EXCLUSION' and IEORRES='Yes');
	column SUBJID IECAT IETEST IEORRES;
	define SUBJID/order;
	define IECAT/order;
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.4: protocol deviations   * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/* TO DO: Add table of number of minor and major deviations. */
 
proc report data=DV spanrows;
	title 'protocol deviations';
	column RID VISIT FORM DVTERM DVCAT;
	define RID/order;
	*define treatment/order;
	define VISIT/order;
	define FORM/order;
run;
/* TO DO: Add specific reason.*/ 

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.5: demographics  * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%asnumeric(code=DM,var=vsorres_weight);
%asnumeric(code=DM,var=vsorres_height);
%asnumeric(code=DM,var=vsorres_bmi);
%asnumeric(code=DM,var=age);

data DM;
	set DM;
	weight=vsorres_weight;
	height=vsorres_height;
	bmi=vsorres_bmi;
run;

proc tabulate data=DM;
	title 'demographics by treatment';
	class treatment sex race;
	var age weight height bmi;
	table (age)*(mean median std min max n)
		(sex race)*(n colpctn='%')
		(weight height bmi)*(mean median std min max n),
		treatment all='both';
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.6: alcohol and smoking * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

%ordervar(code=SU,var=SUOCCUR);
%ordervar(code=SU,var=SUTRT);
%asnumeric(code=SU,var=SUDOSE);

proc tabulate data=SU;
    title 'alcohol and smoking by sequence';
	class treat SUTRT SUOCCUR / order=internal;
    var SUDOSE;
    table SUTRT * SUOCCUR * (n pctn<SUOCCUR>='%')
          SUTRT * SUDOSE *(mean std median min max n),
          treat all='both';
run;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.7: medical history * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

proc report data=MH spanrows;
	title 'medical history';
	where not missing(RID);
	column RID treatment MHTERMPREP MHTERM MHSTDAT MHENDAT MHONGO;
	define RID/order;
	define treat/order;
run;

proc report data=MH;
run;










/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.10: hematology * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/* Data formatting will be different in phase II trial! */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * Subsection 4.18: adverse events * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

data AE;
	set AE;
	if AEREL in ('A') then AEREL='';
	if AEREL1 in ('A') then AEREL1='';
run;


proc report data=AE spanrows;
	title 'adverse events';
	column RID AETERM AESEV AEACN1 AEOUT AEREL AEREL1;
	define RID/order;
run;


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
%add_treat(code=PK);

%asnumeric(code=PK,var=SAMPLETIME);
%asnumeric(code=PK,var=CONCENTRATION);

/* one separate scatterplot for each sample */

proc sgpanel data=PK noautolegend;
	title 'concentration against time by treatment';
	panelby RID/columns=3 rows=4;
	series x=SAMPLETIME y=CONCENTRATION/group=treat markers;
run;

/* one common scatterplot for all samples */

proc means data=PK noprint;
	var CONCENTRATION;
	class SAMPLETIME treat;
	output out=PK_mean mean=mean std=std;
run;

data PK_mean;
	set PK_mean;
	if not missing(SAMPLETIME) and not missing (treat);
	lower=mean-std;
	upper=mean+std;
run;

proc sgplot data=PK_mean;
	title 'concentration against time by treatment';
	series x=SAMPLETIME y=mean / group=treat markers markerattrs=(symbol=CircleFilled);
    xaxis label='time';
    yaxis label='concentration';
    keylegend / title='treatment';
	scatter x=SAMPLETIME y=mean/yerrorlower=lower yerrorupper=upper group=treat;
run;

/* prepare data for WinNonLin */ 

%asnumeric(code=PC,var=PC_DELAY);

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
	keep RID period treat time conc seqence;
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
		You should now see a table with the columns RID, seqence, period, treat, time and conc.

	- 	Perform analysis: Click on 'send to' (in the menu), click on 'NonCompartmental Analysis', click on 'NCA'.
		In the mappings, select 'sort' for the columns RID, seqence, period and treat,
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
		if RID in (&ids_ncs.);
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
