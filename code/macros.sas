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
Arguments: Expects a directory (e.g., 'path="C:\Users\myname\Desktop"')
and a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Imports the file starting with 'code_' and ending with 'xlsx',
and stores it in the data set 'code'.
*/ 

/* extract random ID */
%macro add_rid(code=); 
data &code;
 	set &code;
	RID = input(scan(USUBJID,2,'/'),8.);
run;
%mend add_rid;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
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
%macro add_random(code=);
	data &code;
		merge &code(in=a) random(in=b);
		by RID;
		if a;
	run;
%mend add_random;
/*
Arguments: Expects a CDISC abbreviation (e.g., 'code=VS' for vital signs).
Description: Merges dataset 'code' and dataset 'random' by the random identifier (RID).
This adds information on the treatment sequence to dataset 'code'.
*/

/* import and process clinical data */
%macro prepare;
	%local code i;
	%let code = AE ART ARTT CE DA CM DD DI DM DS DV EG EQ EX GC IE LB LP MH PC PE PM PR QUEST RANKIN VS; /* Also add files without code! */
	%do i = 1 %to %sysfunc(countw(&code));
    	%import(path=&pathClin,code=%scan(&code,&i));
		%add_rid(code=%scan(&code,&i));
		%sort_rid(code=%scan(&code,&i));
		%add_random(code=%scan(&code,&i));
		*%label_vars(code=%scan(&code,&i));
	%end;
%mend prepare;
/*
Arguments: -
Note: Loops through a list of abbreviations (e.g., 'code = VS DM' for vital signs and demographics).
Description: Prepares the datasets by importing the datasets, adding the random identifiers,
sorting the datasets by random identifiers and adding information on the treatment sequence.
NB: Consider adding the argument 'code' and call this macro once for each CDISC domain.
*/

/* assign labels to variables */
%macro label_vars(code=);
	proc datasets lib=work nolist;
		modify &code.;
		label
			USUBJID = "Subject"
			treatment = "Treatment";
	quit;
	%if &code.=DM %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				age = "Age"
				vsorres_weight = "Weight"
				vsorres_height = "Height"
				vsorres_bmi = "BMI"
				SEX = "Sex"
				RACE = "Race";
		quit;
	%end;
	%else %if &code.=MH %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				MHTERMPREP = "Given Reported Term"
				MHTERM_YN = "Status"
				MHTERM = "Other Reported Term"
				MHSTDAT = "Start Date"
				MHENDAT = "End Date"
				MHONGO = "Ongoing"
				System_Organ_Class = "SOC"
				Preferred_Term = "PT";
		quit;
	%end;
	%else %if &code.=PM %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				CMTRT = "Drug, Medication, or Therapy"
				CMDOSE = "Total Daily Dose"
				CMDOSU = "Dose Units"
				CMDOSFRQ = "Dosing Frequency per Interval"
				CMROUTE = "Route of Administration"
				CMINDCREF = "Reason for Prior Medication Specification"
				ATC_CLASSIFICATION_NAME = "ATC";
		quit;
	%end;
	%else %if &code.=IE %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				IECAT = "Category"
				IETEST = "Criterion"
				IEORRES = "Result"
				EC_CHECK = "Check";
		quit;
	%end;
	%else %if &code.=DV %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				FORM = "Page"
				DVTERM = "Deviation"
				DVCAT = "Category";
		quit;
	%end;
	%else %if &code.=ART %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				ARTINITDAT = "Date"
				ARTREGIMEN = "Regimen"
				ENHANCEDART = "Enhanced Adherence Arranged";
		quit;
	%end;
	%else %if &code.=ARTT %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				ARTSTDAT = "start date first regimen"
				ART_FIRST_REGIMEN = "first regimen"
				ART_SWITCH = "switch"
				ARTSTDAT2 = "start date current regimen"
				ART_CURRENT_REGIMEN = "current regimen" 
				ADHERENT_ART = "adherence"
				NB_MISSED_DOSES = "doses missed last month"
				ART_DECISION = "decision"
				VIRAL_LOAD_AVAILABLE = "last viral load available"
				VIRAL_LOAD_RESULT = "viral load (copies per mL)"
				VIRALDAT = "viral load date";
		quit;
	%end;
	%else %if &code.=EX %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				EXDOSNB = "Dose Number"
				EXTRT = "Other Product"
				EXSTDAT = "Date"
				EXSTTIM = "Time"
				EXROUTE = "Route";
		quit;
	%end;
	%else %if &code.=CM %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				CMTRT = "Drug, Medication, or Therapy"
				CMINDC = "Reason"
				CMSTDTC = "Start Date"
				CMENDTC = "End Date"
				CMONGO = "Ongoing"
				ATC_CLASSIFICATION_NAME = "ATC";
		quit;
	%end;
	%else %if &code.=CE %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				CETERM = "Clinical Event";
		quit;
	%end;
	%else %if &code.=AE %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				AESEV = "Severity"
				AESEV_ = "Severity"
				AETERM = "Adverse Event"
				AEOUT = "Outcome" 
				AEREL = "Relation A"
				AEREL1 = "Relation B"
				System_Organ_Class = "SOC"
				Preferred_Term = "PT";
		quit;
	%end;
	%else %if &code.=PE %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				PETESTCD = "Body System Examined"
				PEORRES = "Result"
				PEORRES_SP = "Details";
		quit;
	%end;
	%else %if &code.=VS %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				VSTEST = "Vital Signs Test"
				VSSTRESC = "Result"
				VSPOS = "Position";
		quit;
	%end;
	%else %if &code.=GC %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				BESTEYERESPONSE = "Best Eye Response"
				BESTVERBALRESPONSE = "Best Verbal Response"
				BESTMOTORRESPONSE = "Best Motor Response"
				GCS_TOTAL = "GCS Total";
		quit;
	%end;
	%else %if &code.=LP %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				LPTEST = "Lumbar Puncture Test";
		quit;
	%end;
	%else %if &code.=LB %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				LBTEST = "Laboratory Test"
				/*LBORRES = "Result"*/
				/*LBSTNRC = "Result"*/
				LBCLSIG = "Result";
		quit;
	%end;
	%else %if &code.=XXX %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit";
		quit;
	%end;
	%else %if &code.=EG %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				EGTEST = "ECG Test or Examination"
				EGSTRESC1 = "Result";
		quit;
	%end;
	%else %if &code.=RANKIN %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit";
		quit;
	%end;
	%else %if &code.=DD %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				DSSTATUS = "Vital Status";
		quit;
	%end;
	%else %if &code.=PR %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				PREGORRES = "Result";
		quit;
	%end;
	%else %if %bquote(&code.)=%bquote(EQ) %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				MOBILITY = "Mobility"
				SELFCARE = "Self-Care"
				USUALACTIVITIES = "Usual Activities"
				PAINDISCOMFORT = "Pain, Discomfort"
				ANXIETYDEPRESSION = "Anxiety, Depression"
				SCALE = "Scale"; 
		quit;
	%end;
	%else %if &code.=PC %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				PC_SAMPLING_TIME = "Sampling Time"
				PCTPTREF = "Target Time"
				PCDTC = "Actual Time"
				PC_DELAY_RSN = "Reason"
				PC_DEVIATION = "Deviation"
				PC_DELAY = "Deviation (Minutes)";
		quit;
	%end;
	%else %if &code.=DI %then %do;
		proc datasets lib=work nolist;
			modify &code.;
			label
				VISIT = "Visit"
				LPPERF = "Lumbar Puncture"
				DISCHARGED = "Discharged"
 				DISCHAR_CONTRA = "Counselled for Contraception"
 				FLOCO_MAINT = "Maintenance Fluconazole Prescribed"
 				PATIENT_ART = "ART"
 				REGIMEN_ART = "ART Regimen"
 				ART_ADHER = "Enhanced ART Adherence"
 				TPT_ADMIN = "TPT Administered"
 				REGIMEN_TPT = "TPT Regimen";
		quit;
	%end;
%mend label_vars;
/*
Arguments: Expects an abbreviation (e.g., 'code=VS' for vital signs).
Description: Assigns interpretable labels to variables.
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

/* replace special sign in units */
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
/*
Arguments: Expects an abbreviation (e.g., 'code=VS' for vital signs).
Description: Replaces "/" by " per " in the variable indicating the units.
*/ 

/* add unit to test name */
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
/*
Arguments: Expects an abbreviation (e.g., 'code=VS' for vital signs).
Description: Adds the unit to the name of the test
(e.g., 'temperature' becomes 'temperature (celcius)'). 
*/

/* define variable names */ 
%macro getvars(code=);
	%if &code.=VS %then %do;
		%let label='Vital Sign';
		%let var_test=VSTEST;
		%let var_test_=VSTEST_;
		%let state_by=USUBJID VISIT VSPOS;
		%let var_judge=VSSTRESC;
		%let var_judge_=VSSTRESC_;
		%let var_score=VSORRES;
		%let var_unit=VSORRESU;
	%end;
	%else %if &code.=EG %then %do;
		%let label='Electrocardiogram';
		%let var_test=EGTEST;
		%let var_test_=EGTEST_;
		%let state_by=USUBJID VISIT;
		%let var_judge=EGSTRESC1;
		%let var_judge_=EGSTRESC1_;
		%let var_score=EGORRES;
		%let var_unit=EGORRESU;
	%end;
	%else %if &code.=LB or &code.=LB_temp %then %do;
		%let label='Laboratory';
		%let var_test=LBTEST;
		%let var_test_=LBTEST_;
		%let state_by=USUBJID VISIT;
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
	%else %if &code.=LP %then %do;
		%let label='Lumbar Puncture';
		%let var_test=LPTEST;
		%let var_test_=LPTEST_;
		%let state_by=USUBJID VISIT;
		%let var_judge=;
		%let var_judge_=;
		%let var_score=LPORRES;
		%let var_unit=LPORRESU;
	%end;
	%else %do;
		%put ERROR;
	%end;
	/*
	%put label=&label.;
	%put var_test=&var_test.;
	%put var_test_=&var_test_.;
	%put state_by=&state_by.;
	%put var_score=&var_score.;
	%put var_judge=&var_judge.;
	%put var_judge_=&var_judge_.;
	%put var_unit=&var_unit.;
	*/
%mend getvars;
/*
Argument: Expects an abbreviation (e.g., 'code=VS' for vital signs).
Description: Sets the label and defines various variables.
*/

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
	proc transpose data=long out=wide(drop=_name_); /* _label_*/ 
		by &state_by.;
		id &var_test.;
		/*idlabel &var_test_.;*/
		var &var_score.;
	run;
	/*
	data wide;
		set wide;
		drop _label_;
	run;
	*/
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
%macro report(data=,title=,title2=,name=none,width=);
	options validvarname=any;
	/*
	proc sort data=&data.;
		by RID VISIT;
	run;
	*/
	proc report data=&data. spanrows
	    /*style(report)=[width=100%]*/
        %if %length(&width.) > 0 %then %do;
            style(column)=[cellwidth=&width.]
            style(header)=[cellwidth=&width.]
        %end;
        ;
		%color(name=&name.);
		/*define RID/order order=internal;*/
		define USUBJID/order;
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
%macro list_abnormal(code=,type=,check_visit=,show_visit=,width=);
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
	%report(data=wide,title=&title.,name=&code.,width=&width.);
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
		table 	VISIT * &var_score.='' * (mean std median min max n),
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

/* make tables of values and change in values */
%macro process_table(code=,tests=,position=);
	%local i test;
	%do i = 1 %to %sysfunc(countw(&tests, |));
  		/*%let test = %scan(&tests, &i, |);*/
    	%let test = %qscan(%superq(tests), &i, %str(|), q);
  		%table_values(code=&code.,test="&test",position=&position.);
  		%table_change(code=&code.,test="&test",position=&position.);
	%end;
%mend process_table;
/*
Arguments: Expects an abbreviation (e.g., 'code=VS' for vital signs),
a test (e.g., 'test=Systolic Blood Pressure (mmHg)'),
and a position (e.g., 'position=Standing').
Description: Makes the corresponding tables.
*/

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
	proc sort data=DATA_DIFF;
		by RID VISIT;
	run;
	data DATA_DIFF;
  		do until(last.RID);
     		set DATA_DIFF;
     		by RID;
     		if treatment = 'Immediate-Release (IR)' then do;
        		if baseA = . then baseA = &var_score.;
        		change = &var_score. - baseA;
     		end;
			drop baseA;
     		else if treatment = 'Sustained-Release (SR)' then do;
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
		table 	VISIT * change='' * (mean std median min max n),
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
		by RID VISIT;
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
		series x=VISIT y=&var_score. / group=USUBJID markers;
    	%title(type="figure",label="Trajectories of %sysfunc(dequote(&test.))"); /*%sysfunc(dequote(&position.))*/
		title2 '(for those abnormal at' &check_visit. ')';
    	xaxis label='time'; 
    	yaxis label='value';
   		keylegend / title='Subject';
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
	proc means data=&code. mean clm alpha=0.05 noprint nway;
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
	proc means data=DATA_DIFF mean clm alpha=0.05 noprint nway;
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

/* plot mean values and mean change */
%macro process_trend(code=,tests=,position=);
	%local i test;
	%do i = 1 %to %sysfunc(countw(&tests, |));
  	%let test = %scan(&tests, &i, |);
  		%plot_mean_value(code=&code.,test="&test",position=&position.);
  		%plot_mean_change(code=&code.,test="&test",position=&position.);
	%end;
%mend process_trend;
/*
Arguments: Expects an abbreviation (e.g., 'code=VS' for vital signs),
a test (e.g., test='Systolic Blood Pressure (mmHg)'),
and a position (e.g. 'position=Standing')
Description: Plots the mean values and the mean change.
*/

/* plot trajectories of multiple tests */
%macro process_traject(code=,check_visit=,tests=,position=);
	%local i test;
	%do i=1 %to %sysfunc(countw(&tests, |));
	%let test = %scan(&tests, &i, |);
		%plot_traject(code=&code.,check_visit=&check_visit.,test="&test",position=&position.);
	%end;
%mend process_traject;
/*
Arguments: Expects an abbreviation (e.g., code=VS),
the visit where patients are checked for abnormalities (e.g., check_visit=baseline),
the tests, and the position (if applicable).
Description: Plots trajectories of multiple tests.
*/

/* make table of normal/abnormal counts and summary statistics */
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
				&var_test. * &var_score.='' * (mean std median min max n),
				treatment all='Total';
	run;
%mend tabulate;
/*
Arguments: Expects an abbreviation,
a type if there are multiple types of values for a visit,
and a visit.
Description: Makes the corresponding tables.
*/

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
