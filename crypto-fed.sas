
/* FED STUDY */

/* clean workspace */

proc datasets library=work kill;
run;
dm 'odsresults; clear';
dm "log; clear; ";
options nosource;
options nonotes;

/* define paths */

%let pathRand=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-02-CM (fed study)\9 - Final analysis\Data;
%let pathClin=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-02-CM (fed study)\4 - Data Management\7-Data transfers\Export files\24032023;
%let pathPhar=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-02-CM (fed study)\4 - Data Management\7-Data transfers\Import files\15032023_Pharmetheus\0131FRM18_DNDi-5FC-02-CM_PK_20230315\0131FRM18_DNDi-5FC-02-CM_PK_20230315;
%let pathOut=C:\Users\arauschenberger\Desktop\Crypto-HIV\learning_SAS;

/* import randomisation list */ 

proc import datafile="&pathRand.\Randomizationlist"
		out=random
		dbms=xlsx;
run;

data random;
	set random;
	rename Subject_ID=RID;
	if seqence=1 then
		seq='1 (AB)';
	else
		seq='2 (BA)';
run;

/* import clinical data */
%macro import(path,code);
proc import datafile="&path.\&code._*"
    out=&code
    dbms=xlsx
	REPLACE;
run;
%mend import;
/*
Arguments: Specify a directory (e.g., path="C:\Users\myname\Desktop") and a CDISC abbreviation (e.g., code=DM for demographics or code=VS for vital signs).
Description: Imports the file starting with 'code_' and ending with 'xlsx' and stores it in the data set 'code'.
*/ 

/* extract random ID */
%macro add_rid(code); 
data &code;
 	set &code;
 	RID = input(substr(USUBJID,index(USUBJID,'/')+1),best.);
run;
%mend add_rid;
/*
Arguments: Specify a CDISC abbreviation (e.g., code=DM or code=VS).
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
Arguments: Specify a CDISC abbreviation (e.g., code=DM or code=VS).
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
Arguments: Specify a CDISC abbreviation (e.g., code=DM or code=VS).
Description: Merges dataset 'code' and dataset 'random' by the random identifier (RID),
adding information on the treatment sequence to dataset 'code'.
*/

/* import and process clinical data */
%macro prepare;
   %let code = IE AE DM DS DV SU MH VS EG LB PC; /* add other abbreviations*/
   %do i = 1 %to %sysfunc(countw(&code));
      %import(&pathClin,%scan(&code,&i));
	  %add_rid(%scan(&code,&i));
	  %sort_rid(%scan(&code,&i));
	  %add_seq(%scan(&code,&i));
   %end;
%mend prepare;
/*
Options: Define list of abbreviations (code = ...).
Description: Prepares the datasets by importing the datasets, adding the random identifiers,
sorting the datasets by random identifiers and adding information on the treatment sequence.
*/

%prepare;

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
Arguments: Specify a CDISC abbreviation (e.g. code=DM or code=VS) and a variable name (var=...).
Description: Converts character variable to numeric.
*/

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
	value	sup_pul 	low-40=&low.
						40-100='white'
						100-high=&high.;
	value	sta_sys 	low-85=&low.
						85-150='white'
						150-high=&high.;
	value	sta_dia 	low-50=&low.
						50-95='white'
						95-high=&high.;
	value	sta_pul 	low-40=&low.
						40-100='white'
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
run; 

/* colour extreme values */ 
%macro color(name);
	%if &name.='VS' %then %do;
	compute Temperature;
		call define(_col_,'style','style={background=temp.}');
	endcomp;
	compute Systolic_Blood_Pressure;
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_sys.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_sys.}');
		end;
	endcomp;
	compute Diastolic_Blood_Pressure;
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_dia.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_dia.}');
		end;
	endcomp;
	compute Pulse_Rate;
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_pul.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_pul.}');
		end;
	endcomp;
	%end;
	%if &name.='EG' %then %do;
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
%mend color;
/*
Arguments: Choose one of two CDISC abbreviations (either 'VS' or 'EG').
Description: This macro uses colour for values below or above the normal range.
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
Arguments: Specify a CDISC abbreviation (e.g. code=DM or code=VS).
Description: This macro uses the variable 'VISIT' to create the variable 'period'.
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
Arguments: Specify a CDISC abbreviation (e.g. code=DM or code=VS).
Description: This macro uses the variable for the period (1 or 2)
and the variable for the treatment sequence (AB or BA)
to create the variable for the treatment (A or B).
*/

/* withdrawals */

data DS;
	set DS;
	if DSTERM='DISCONTINUED' then withdraw='yes';
	else withdraw='no';
run;

proc tabulate data=DS;
	where VISIT='Post Study';
	class seq withdraw;
	table withdraw * (n colpctn),
			seq all='both';
	title 'early withdrawals';
run;

proc print data=DS;
	where DSTERM='DISCONTINUED';
	var RID seq;
	title 'lising of withdrawals';
run;

/* ineligibility */

proc report data=IE spanrows;
	column SUBJID IECAT IETEST IESTRESC;
	where (IECAT='INCLUSION' and IESTRESC='No') or (IECAT='EXCLUSION' and IESTRESC='Yes');
	define SUBJID/order;
	define IECAT/order;
	title 'listing of ineligible samples';
run;

/* protocol deviations */

proc report data=DV spanrows;
	column RID seq VISIT FORM DVTERM DVCAT;
	define RID/order;
	define seq/order;
	define VISIT/order;
	define FORM/order;
	title 'protocol deviations';
run;

/* demographics */

%asnumeric(DM,vsorres_weight);
%asnumeric(DM,vsorres_height);
%asnumeric(DM,vsorres_bmi);
%asnumeric(DM,age);

data DM;
	set DM;
	weight=vsorres_weight;
	height=vsorres_height;
	bmi=vsorres_bmi;
run;

proc tabulate data=DM;
	class seq sex race;
	var age weight height bmi;
	table (age)*(mean median std min max n)
		(sex race)*(n colpctn)
		(weight height bmi)*(mean median std min max n),
		seq all='both';
	title 'demographics';
run;

/* alcohol and smoking */

%asnumeric(SU,SUDOSE);

proc tabulate data=SU;
    class seq SUTRT SUOCCUR / mlf order=data;
    var SUDOSE;
    table SUTRT * SUOCCUR * n
          SUTRT * SUDOSE *(mean std median min max n),
          seq all='both';
    title "alcohol and smoking";
run;

/* medical history */

proc report data=MH spanrows;
	column RID seq MHTERM MHSTDAT MHENDAT MHONGO;
	where not missing(RID);
	define RID/order;
	define seq/order;
	title 'medical history';
run;

/* vital signs */

proc format;
	invalue pagename_invalue
		'ECG' = 0
 		'ECG - 2 hours post-dose - only for Ancotil' = 2
 		'ECG - 4 hours post-dose - only for Flucitosine' = 4
 		'ECG - 8 hours (2 hours after 2nd dose Ancotil)' = 8
		'ECG - 48 hours post-dose' = 48
		other = .;
	value pagename_value
		0 = 'ECG'
 		2 = 'ECG - 2 hours post-dose - only for Ancotil'
 		4 = 'ECG - 4 hours post-dose - only for Flucitosine'
 		8 = 'ECG - 8 hours (2 hours after 2nd dose Ancotil)'
		48 = 'ECG - 48 hours post-dose'
		other = '-';
	invalue visit_invalue
		'screen' = 0.00 
		'P1: pre-dose' = 1.00
		'P1: 2h' = 1.02 
		'P1: 4h' = 1.04 
		'P1: 6h' = 1.06 
		'P1: 48h' = 1.48
		'P2: pre-dose' = 2.00 
		'P2: 2h' = 2.02 
		'P2: 4h' = 2.04 
		'P2: 6h' = 2.06 
		'P2: 48h' = 2.48 
		'post-study' = 3.00 
		other = .;
	value visit_value
		0.00 = 'screen'
		1.00 = 'P1: pre-dose'
		1.02 = 'P1: 2h'
		1.04 = 'P1: 4h'
		1.06 = 'P1: 6h'
		1.48 = 'P1: 48h'
		2.00 = 'P2: pre-dose'
		2.02 = 'P2: 2h'
		2.04 = 'P2: 4h'
		2.06 = 'P2: 6h'
		2.48 = 'P2: 48h'
		3.00 = 'post-study' 
		other = '-';
	invalue form_invalue
		'Pre-dose' = 0
		'2 hours post-dose' = 2
		'4 hours post-dose' = 4
		'6 hours post-dose' = 6
		'48 hours post-dose' = 48
		other = .; 
	value form_value
		0 = 'Pre-dose'
		2 = '2 hours post-dose'
		4 = '4 hours post-dose'
		6 = '6 hours post-dose'
		48 = '48 hours post-dose'
		other = '-'; 
run;

data EG;
	set EG;
	temp = input(PAGENAME,pagename_invalue.);
	format temp pagename_value.;
	drop PAGENAME;
	rename temp=PAGENAME;
run;

%asnumeric(VS,VSORRES);

data VS;
	set VS;
	if VSPOS in (' ','.') then VSPOS='N/A';
run;

proc tabulate data=VS;
	where VISIT='Screening Visit';
	class seq VSPOS VSTEST VSSTRESC;
	var VSORRES;
	table	VSPOS * VSTEST * VSSTRESC * (N)
			VSPOS * VSTEST * VSORRES * (mean std median min max N),
			seq all='both';
	title "vital signs";
run;

/* vital signs - screening - listing */

/* The macro 'listncs' returns the randomisation identifiers for the dataset VS or EG with abnormal results at a specific visit.*/ 
%macro listncs(code,visit);
	%global ids_ncs;
	%if &code.=VS %then %do;
		%let var_test=VSSTRESC;
	%end;
	%else %if &code.=EG %then %do;
		%let var_test=EGSTRESC1;
	%end;
	%else %do;
		%put ERROR;
	%end;
    data temp;
        set &code.;
        where VISIT in (&visit.) and &var_test. in ('NCS','Abnormal, NCS') and not missing(RID);
    run;
    proc sql noprint;
        select distinct RID
        into :ids_ncs separated by ','
        from temp;
    quit;
	%let ids_ncs=&ids_ncs.;
	%put ids_ncs=&ids_ncs.;
%mend listncs;

%macro showncs(code,visit,name);
	%if &name.='VS' %then %do;
		%let var_id=VSTEST;
		%let state_by=RID VISIT VSPOS FORM;
		%let var=VSORRES;
	%end;
	%else %if &name.='EG' %then %do;
		%let var_id=EGTEST;
		%let state_by=RID VISIT PAGENAME;
		%let var=EGORRES;
	%end;
	data long;
		set &code.;
		if RID in (&ids_ncs.);
		if VISIT in (&visit.);
	run; 
	proc sort data=long;
		by &state_by.;
	run;
	proc transpose data=long out=wide;
		by &state_by.;
		id &var_id.;
		var &var.;
	run;
%mend;

%macro report(data,title,name);
	proc report data=&data. spanrows;
		%color(name=&name.);
		define RID / order order=internal;
		define VISIT / order order=internal;
		%if &name.='EG' %then %do;
			define PAGENAME / order order=internal;
		%end;
		define _NAME_/noprint;
		title &title.;
	run;
%mend;

%listncs(code=VS,visit='Screening Visit');
%showncs(code=VS,visit='Screening Visit' 'Unscheduled Screening',name='VS');
%report(data=wide,title="patients with abnormal NCS - screening visits",name='VS');

/*
CONTINUE HERE: Combine all three macros, allow for PAGENAME.
- arguments: data, check_visit, show_visit
*/ 

/* lead ECG */

%asnumeric(EG,EGORRES);

data EG;
	set EG;
	measure = cat(EGTEST,'(',EGORRESU,')');
run;

proc tabulate data=EG;
	where VISIT="SCREENING";
	class seq measure EGSTRESC1;
	var EGORRES;
	table 	measure * EGSTRESC1 * n
			measure * EGORRES * (mean std median min max n),
			seq all='both';
	title "ECG";
run;

/* ECG - screening - listing */ 

%listncs(code=EG,visit='SCREENING');
%showncs(code=EG,visit='SCREENING' 'Unscheduled Screening',name='EG');
%report(wide,title="patients with abnormal ECG - screening visits",name='EG');

/* hematology: data formatting will be different in actual clinical trial */

/* vital signs - values */

%add_period(VS);
%add_treat(VS);

data VS;
	set VS;
	length time $40;
	if VISIT='Screening Visit' then time='screen';
	else if FORM='Pre-dose' then time=cat('P',period,': pre-dose');
	else if FORM='2 hours post-dose' then time=cat('P',period,': 2h');
	else if FORM='4 hours post-dose' then time=cat('P',period,': 4h');
	else if FORM='6 hours post-dose' then time=cat('P',period,': 6h');
	else if FORM='48 hours post-dose' then time=cat('P',period,': 48h');
	else if VISIT='Post Study' then time='post-study';
	else time='other';
run;

/*
data VS;
	set VS;
	temp = input(time,visit_invalue.);
	format temp visit_value.;
	drop time;
	rename temp=time;
run;
*/

/* summarise vital signs - values */ 
%macro tabval(test,position='Supine');
	proc tabulate data=VS;
		where VSPOS=&position. and VSTEST=&test.;
		class VISIT treat FORM / mlf order=data;
		var VSORRES;
		table 	FORM * VSORRES * (mean std median min max n),
			treat;
		title &position. &test. "- values";
	run;
%mend tabval;
/*
Arguments: Select 'test' from 'Systolic Blood Pressure', 'Diastolic Blood Pressure' and 'Pulse Rate',
and select 'position' from 'Supine' and 'Standing'.
Description: Summarises measurements for each time point (rows) and treatment (columns).
*/ 

/* calculate change */
%macro calcdiff(test,position='Supine');
	data temp;
		set VS;
		where VSTEST=&test. and VSPOS=&position. and not missing(RID) and not missing(period);
	run;
	data temp;
  		do until(last.RID);
     		set temp;
     		by RID;
     		if treat = 'A' then do;
        		if baseA = . then baseA = VSORRES;
        		diff = VSORRES - baseA;
     		end;
			drop baseA;
     		else if treat = 'B' then do;
        		if baseB = . then baseB = VSORRES;
				diff = VSORRES - baseB;
    		end;
			drop baseB;
 		output;
		end;
	run;
%mend calcdiff;
/*
Arguments: Select 'test' from 'Systolic Blood Pressure', 'Diastolic Blood Pressure' and 'Pulse Rate',
and select 'position' from 'Supine' and 'Standing'.
*/

/* summarise vital signs - change */
%macro tabdiff(test,position='Supine');
proc tabulate data=temp;
	class VISIT treat FORM / mlf order=data;
	var diff;
	table 	FORM * diff * (mean std median min max n),
			treat;
	title &position. &test. "- change";
run;
%mend;
/*
Arguments: Select 'test' from 'Systolic Blood Pressure', 'Diastolic Blood Pressure' and 'Pulse Rate',
and select 'position' from 'Supine' and 'Standing'.
Description: Summarises change with respect to pre-dose for each time point (rows) and treatment (columns).
*/ 

/* vital signs - both */

%tabval('Systolic Blood Pressure');
%calcdiff('Systolic Blood Pressure');
%tabdiff('Systolic Blood Pressure');

%tabval('Diastolic Blood Pressure');
%calcdiff('Diastolic Blood Pressure');
%tabdiff('Diastolic Blood Pressure');

%tabval('Pulse Rate');
%calcdiff('Pulse Rate');
%tabdiff('Pulse Rate');

/* vital signs - normal/abnormal */

proc format; 
	value $visit_order
	'screen'='0.00'
	'P1: pre-dose'='1.00'
	'P1: 2h'='1.02'
	'P1: 4h'='1.04'
	'P1: 6h'='1.06'
	'P1: 48h'='1.48'
	'P2: pre-dose'='2.00'
	'P2: 2h'='2.02'
	'P2: 4h'='2.04'
	'P2: 6h'='2.06'
	'P2: 48h'='2.48'
	'post-study'='3.00'; 
run;

/* also use value and invalue ! */ 

proc summary data=VS nway;
	where not missing(RID) and not missing(period);
	class VSSTRESC RID FORM treat time;
	output out=temp;
run;

data temp;
	set temp;
	visit_order = put(time,$visit_order.);
run;

proc sort data=temp;
	by visit_order;
run;

proc tabulate data=temp;
	class treat VSSTRESC RID FORM / mlf order=data;
	table FORM * VSSTRESC * n,
		  treat;
	title 'vital signs results';
run;

/* vital signs - listing abnormal */

data long;
	set VS;
	where VSSTRESC='NCS' and not missing(RID) and VISIT in ('Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD');
run;

proc sort data=long;
	by RID treat period VISIT FORM VSPOS;
run;

proc transpose data=long out=wide;
	by RID treat period VISIT FORM VSPOS;
	id VSTEST;
	var VSORRES;
run;

%report(wide,title="patients with abnormal NCS - scheduled visits",name='VS');

%listncs(code=VS,visit='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD');
%showncs(code=VS,visit='Unscheduled Treatment Period 1' 'Unscheduled Treatment Period 2',name='VS');
%report(wide,title="patients with abnormal NCS - unscheduled visits",name='VS');

/* vital signs - trajectory */

/* use propose time formatting (keep this code)

data VS;
	set VS;
	temp = input(VSDAT, ddmmyy10.);
	date = put(temp, yymmdd10.);
	VSDTC = catx("T",date,VSTIM);
	/* datetime = input(VSDTC, E8601DT.);
	drop temp;
run;

proc sort data=VS;
	by RID VSDTC;
run;

data VS;
	set VS;
	before = lag(time);
	if time='other' then do;
		time = before || " - us";
	end;
	drop before;
run;

proc print data=VS;
run;

/* end temporary */  

/*
start temporary

proc sort data=VS;
	by RID datetime;
run;

proc tabulate data=VS;
	class VISIT;
	table VISIT;
run;

proc print data=VS;
run;

end temporary
*/ 

/*
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
*/

/*
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

/* plot trajectories of vital signs */
%macro plotind(test,position='Supine');
	data temp;
		set VS;
		where VSTEST=&test. and VSPOS=&position.; /*and time ne 'other'*/
		if RID in (&ids_ncs.);
	run;
	proc sort data=temp;
		by RID VSDTC;
	run;
	data temp;
		set temp;
		time_lag = lag(time);
		if time='other' then do;
			time = time_lag;
		end;
		/*visit_order = put(time,$visit_order.);*/
		drop time_lag;
	run;
	proc sgplot data=temp;
		series x=time y=VSORRES / group=RID markers;
    	title &position. " " &test.;
    	xaxis label='time';
    	yaxis label='value';
   		keylegend / title='RID';
		%if &test.='Systolic Blood Pressure' %then %do;
			refline 90 140 / axis=y;
		%end;
		%if &test.='Diastolic Blood Pressure' %then %do;
			refline 45 90 / axis=y;
		%end;
	run;
%mend plotind;
/*
Arguments: Choose between test='Systolic Blood Pressure' and test='Diastolic Blood Pressure',
and choose between position='Supine' (default) and position='Standing'.
Description: Extracts data from the dataset 'VS'  for the individuals in 'ids_ncs',
the position 'Supine' and the chosen test (see arguments).
Sorts the extracted data by the sample identifier and the time point.
Replaces missing visit names by the visit name of the lagged time point.
Plots the measurements against the visit names, with one line for each patient.
*/ 

/*
CONTINUE HERE: Replace global variables in macros by macro variables.
Macros should also show all arguments in the output (e.g., figure caption).
*/

%plotind('Systolic Blood Pressure');
%plotind('Diastolic Blood Pressure');

/* TO DO:  Add unscheduled visit between schedules visits. */ 

/* ISSUE: Define order of time. Format time object. */

/* vital signs - sample means (and change) */

proc format; 
	value $form 
	'Pre-dose'='00'
	'2 hours post-dose'='02'
	'4 hours post-dose'='04'
	'6 hours post-dose'='06'
	'48 hours post-dose'='48'; 
run; 

/* Also use value and invalue? */ 

/* plot mean value or mean change */
%macro plot_internal(title);
	data VS_means;
		set VS_means;
		where not missing(treat) and not missing(FORM);
		visit_format = put(FORM,$form.);
	run;
	proc sort data=VS_means;
		by visit_format;
	run;
	proc sgplot data=VS_means;
		series x=FORM y=mean / group=treat markers markerattrs=(symbol=CircleFilled);
    	title &title.;
    	xaxis label='time';
    	yaxis label='value';
    	keylegend / title='treatment';
		highlow x=FORM low=lclm high=uclm / group=treat;
		scatter x=FORM y=mean/yerrorlower=lclm yerrorupper=uclm group=treat;
	run;
%mend plot_internal;
%macro plot_mean_value(test,position='Supine');
	proc means data=VS mean clm alpha=0.05 noprint;
		where VSTEST=&test. and VSPOS=&position.;
		var VSORRES;
		class treat FORM;
		output out=VS_means mean=mean lclm=lclm uclm=uclm;
	run;
	%plot_internal(title="Mean " &position. " " &test.);
%mend plot_mean_value;
%macro plot_mean_change(test,position='Supine');
	%calcdiff(&test.);
	proc means data=temp mean clm alpha=0.05 noprint;
		where VSTEST=&test. and VSPOS=&position.;
		var diff;
		class treat FORM;
		output out=VS_means mean=mean lclm=lclm uclm=uclm;
	run;
	%plot_internal(title="Mean change in " &position. " " &test.);
%mend plot_mean_change;
/*
Arguments: Set 'test' to 'Systolic Blood Pressure', 'Diastolic Blood Pressure' or 'Pulse Rate',
and set 'position' to 'Supine' (default) or 'Standing'.
Description: Extracts the data from dataset 'VS' for the selected position and the selected test.
Optionally (plot_mean_change), computes the differences with respect to the pre-dose measurement.
Calculates the means of these measurement for the two treatments (A and B)
and the different time points (pre-dose, 2/4/6/48 hours postdose),
as well as the lower and upper confidence limits for these means.
Plots the results.
*/ 

%plot_mean_value('Systolic Blood Pressure');
%plot_mean_change('Systolic Blood Pressure');

/*
omitted: similar calls for Diastolic Blood Pressure and Pulse Rate

%plot_mean_value('Diastolic Blood Pressure');
%plot_mean_change('Diastolic Blood Pressure');

%plot_mean_value('Pulse Rate');
%plot_mean_change('Pulse Rate');
*/

/* vital signs - post study */ 

proc tabulate data=VS;
	where visit='Post Study';
	class seq VSPOS VSTEST VSSTRESC;
	var VSORRES;
	table	VSPOS * VSTEST * VSSTRESC * (N)
			VSPOS * VSTEST * VSORRES * (mean std median min max N),
			seq all='both';
	title "vital signs - post study";
run;

/* vital signs - overall change */

data long;
	set VS;
	where VISIT in ('Screening Visit','Post Study') and VSPOS='Supine' and not missing(RID);
run;

proc sort data=long;
	by RID VSTEST;
run;

proc transpose data=long out=wide;
	by RID VSTEST seq;
	id VISIT;
	var VSORRES;
run;

data wide;
	set wide;
	diff = Post_Study - Screening_Visit;
run;

proc tabulate data=wide;
	class seq RID VSTEST / mlf order=data;
	var diff;
	table VSTEST * diff * (mean std median min max n), seq;
	title 'vital signs - change from screening to post study';
run;

/* ECG during treatment */

%add_period(EG);
%add_treat(EG);

proc tabulate data=EG;
	class treat EGTEST PAGENAME / order=internal;
	where not missing(RID) and PAGENAME ne 1; /* was PAGENAME ne 'ECG' */ 
	var EGORRES;
	table EGTEST*EGORRES * (mean std median min max N), treat*PAGENAME;
	title 'ECG during treatment';
run;

/* abnormal ECG results during treatment */

%let visits='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD';
%listncs(code=EG,visit=&visits);
%showncs(code=EG,visit='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD',name='EG');
%report(wide,title="patients with abnormal ECG - treatment period",name='EG');

/* abnormal ECG results post study (CONTINUE HERE) */

%listncs(code=EG,visit='Post Study');
%showncs(code=EG,visit='Post Study',name='EG');
%report(wide,title="patients with abnormal ECG - post study",name='EG');

/* adverse events */ 

proc report data=AE spanrows;
	column RID AETERM AESEV AEACN1 AEOUT AEREL AEREL1;
	define RID/order;
	title 'adverse events';
run;

/*--- PHARMACOKINETICS ---*/ 

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

%add_seq(PK);
%add_treat(PK);

%asnumeric(PK,SAMPLETIME);
%asnumeric(PK,CONCENTRATION);

/* one separate scatterplot for each sample */

proc sgpanel data=PK noautolegend;
	panelby RID/columns=3 rows=4;
	series x=SAMPLETIME y=CONCENTRATION/group=treat markers;
	title 'concentration against time by treatment';
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
	series x=SAMPLETIME y=mean / group=treat markers markerattrs=(symbol=CircleFilled);
    title 'concentration against time by treatment';
    xaxis label='time';
    yaxis label='concentration';
    keylegend / title='treatment';
	scatter x=SAMPLETIME y=mean/yerrorlower=lower yerrorupper=upper group=treat;
run;

/* prepare data for WinNonLin */ 

%asnumeric(PC,PC_DELAY);

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
        seq='1 (AB)';
    else if seqence=2 then
        seq='2 (BA)';
    else
        seq='';
run;

data PKpars;
 	set PKpars;
	logCmax = log(Cmax);
	logAUClast = log(AUClast); /* Note difference between AUClast (last positive measurement) and AUCall (last measurement) */
	logAUCinf = log(AUCINF_obs); 
run;

/* mixed model */

%macro mixmod(outcome,data=PKpars,class=rid seq period treat,fixed=seq period treat,random=rid(seq),lsmeans=treat);
	proc mixed data=&data.;
		Class &class.;
		Model &outcome.= &fixed. / ddfm=kr; /* was seq period treat  */ 
		Random &random. / type=vc; /* was rid(seq) */
		lsmeans &lsmeans. /cl alpha=0.10; /* was treat*/ 
		Estimate 'diff B-A' treat -1 1/cl alpha = 0.10;
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

%mixmod(logCmax);
%mixmod(logAUClast);
%mixmod(logAUCinf);

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

/* randomisation schedule */ 

proc format;
	value treatment 1='control'
 					2='experimental';
	value country 	1='Tanzania'
					2='Malawi';
	value hospital 	1='Mwananyamala Hospital (Dar es Salaam, Tanzania)'
					2='Amana Hospital (Dar es Salaam, Tanzania)'
					3='Kamuzu Central Hospital (Lilongwe, Malawi)';
run;

proc plan seed=20240103;
	factors hospital=3 block=10 random treatment=6 random/noprint;
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
	RID=catx('.',hospital,put(count,z2.));
run;

%macro scheme(first_name,last_name);
ods pdf file="&pathOut./randomisation_&last_name..pdf" style=grayscaleprinter;
title1 font=timesroman "Randomisation list for";
title2 font=timesroman bold "'A 10 week, open-label, randomized, controlled parallel-group trial to evaluate the comparative bioavailability, 
efficacy and safety of sustained-release flucytosine versus immediate-release flucytosine in adults with cryptococcal meningitis'";
title3 font=timesroman "(confidential copy for &first_name. &last_name.)";
title4 font=timesroman color=red "THESE ARE DUMMY DATA - NOT MEANT FOR REAL USE";
footnote1 justify=left font=timesroman "control treatment: immediate release, experimental treatment: sustained release";
footnote2 justify=left font=timesroman "Please note that this is a watermarked copy.";
footnote3 justify=left font=timesroman color=white "This copy is for &first_name. &last_name..";
proc report data=rand spanrows;
	column hospital block RID treatment;
	define hospital/order order=internal format=hospital.;
	define block/order;
	define treatment/format=treatment.;
run;
ods pdf close;
footnote;
%mend scheme;

/*%scheme(first_name=Armin,last_name=Rauschenberger);*/
/*%scheme(first_name=Michel,last_name=Vaillant);*/


/* ------------- */
/* --- NOTES --- */
/* ------------- */

/*
CONTINUE HERE:
- SAS: save table as postscript
- markdown: visualise postscript
*/

/*
Things to do:

- mixed models: combine tables
- vital signs: solve date/time issue
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

ods pdf file="&pathOut.\mixedmodel.pdf" style=journal;
run;
SOME CODE
ods pdf close;
*/

/* export tables and figures to LaTeX */

/*
tagsets.TablesOnlyLaTeX
*/

/*



ods tagsets.TablesOnlyLaTeX file="&pathOut./table_example.tex" stylesheet="pathOut./sas.sty"(url="sas");
ods pdf file="&pathOut./table_example.pdf";
proc report data=AE spanrows;
	column RID AETERM AESEV AEACN1 AEOUT AEREL AEREL1;
	define RID/order;
	title 'adverse events';
run;
pds pdf close;
ods tagsets.TablesOnlyLaTeX close;




/*
ods pdf file="&pathOut./trial_report.pdf" style=grayscaleprinter startpage=no;
ods pdf close;
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
