
/* FED STUDY */

/* clean workspace */

dm 'odsresults; clear';
dm "log; clear; ";
proc datasets library=work kill;
run;
%symdel _all_;

/* option for log */

options nosource;
options nonotes;
/*options source notes errors=4;*/

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
	/*RID = input(RID, best.);*/
	if seqence=1 then
		seq='1 (AB)';
	else
		seq='2 (BA)';
	/*drop Subject_ID;*/
run;

/* import clinical data */

%macro import(path,file);
proc import datafile="&path.\&file._*"
    out=&file
    dbms=xlsx
	REPLACE;
run;
%mend import;

/* extract random ID */

%macro add_rid(file); 
data &file;
 	set &file;
 	RID = input(substr(USUBJID,index(USUBJID,'/')+1),best.);
run;
%mend add_rid;

/* sort by random ID */

%macro sort_rid(file);
	proc sort data=&file;
		by RID;
	run;
%mend sort_rid;

/* add random info */

%macro add_seq(file);
	data &file;
		merge &file(in=a) random(in=b);
		by RID;
		if a;
	run;
%mend add_seq;

/* import and process clinical data */

%macro prepare;
   %let code = IE AE DM DS DV SU MH VS EG LB; /* add other abbreviations*/
   %do i = 1 %to %sysfunc(countw(&code));
      %import(&pathClin,%scan(&code,&i));
	  %add_rid(%scan(&code,&i));
	  %sort_rid(%scan(&code,&i));
	  %add_seq(%scan(&code,&i));
   %end;
%mend prepare;

%prepare;

/* convert character to numeric */

%macro asnumeric(file,var);
data &file;
	set &file;
	temp = input(&var,best.);
	drop &var;
	rename temp=&var;
run;
%mend asnumeric;

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

/* vital signs - listing */ 

/* The macro 'listncs' returns the randomisation identifiers for the dataset VS or EG with abnormal results at a specific visit.*/ 
%macro listncs(code,visit);
	%global ids_ncs;
	%if &code.=VS %then %do;
		%let var_test=VSSTRESC;
	%end;
	%else %do;
		%let var_test=EGSTRESC1;
	%end;
	%put var_test=&var_test.;
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

%listncs(code=VS,visit='Screening Visit');

data long;
	set VS;
	if RID in (&ids_ncs.);
	if VISIT in ('Screening Visit','Unscheduled Screening');
run; 

proc sort data=long;
	by RID VISIT VSPOS;
run;

proc transpose data=long out=wide;
	by RID VISIT VSPOS;
	id VSTEST;
	var VSORRES;
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

%macro color;
	/*%if data=VS %then %do;*/
	compute Temperature;
		call define(_col_,'style','style={background=temp.}');
	endcomp;
	/*%end;*/
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
%mend color;

/* CONTINUE HERE: condition computation on availability of a column */ 

%macro report(data,title);
	proc report data=&data. spanrows;
		%color;
		define RID/order;
		define VISIT/order;
		define _NAME_/noprint;
		title &title.;
	run;
%mend;

%report(wide,title="patients with abnormal NCS - screening visits");

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

/* ECG - listing */ 

%listncs(code=EG,visit='SCREENING');

data long;
	set EG;
	if RID in (&ids_ncs.);
	if VISIT in ('SCREENING','Unscheduled Screening');
run; 

proc transpose data=long out=wide;
	by RID VISIT;
	id EGTEST;
	var EGORRES;
run;

%report(wide,title="patients with abnormal ECG - screening visits");

/* hematology: data formatting will be different in actual clinical trial */

/* vital signs - values */

%macro add_period(code);
	data &code.;
		set &code.;
		if VISIT in ('Treatment Period 1: 30 hrs PD','Unscheduled Treatment Period 1') then period='1';
		else if VISIT in ('Treatment Period 2: 30 hrs PD','Unscheduled Treatment Period 2') then period='2';
		else period = '';
	run;
%mend add_period;

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

%add_period(VS);
%add_treat(VS);

/*
data VS;
	set VS;
	if VISIT='Screening Visit' then time=-1;
	else if FORM='Pre-dose' then time=0;
	else if FORM='2 hours post-dose' then time=1;
	else if FORM='4 hours post-dose' then time=2;
	else if FORM='6 hours post-dose' then time=3;
	else if FORM='48 hours post-dose' then time=4;
	else if VISIT='Post Study' then time=5;
	else time=.;
run;
*/

data VS;
	set VS;
	length time $40;
	if VISIT='Screening Visit' then time='P0';
	else if FORM='Pre-dose' then time=cat('P',period,'T1');
	else if FORM='2 hours post-dose' then time=cat('P',period,'T2');
	else if FORM='4 hours post-dose' then time=cat('P',period,'T3');
	else if FORM='6 hours post-dose' then time=cat('P',period,'T4');
	else if FORM='48 hours post-dose' then time=cat('P',period,'T5');
	else if VISIT='Post Study' then time='P3';
	else if VISIT='Unscheduled Treatment Period 1' then time='P1X';
	else if VISIT='Unscheduled Treatment Period 2' then time='P2X';
	else time=.;
run;

/*
data VS;
	set VS;
	length time $40;
	if VISIT='Screening Visit' then time='screen';
	else if FORM='Pre-dose' then time=cat('P',period,'pre');
	else if FORM='2 hours post-dose' then time=cat('P',period,'H2');
	else if FORM='4 hours post-dose' then time=cat('P',period,'H4');
	else if FORM='6 hours post-dose' then time=cat('P',period,'H6');
	else if FORM='48 hours post-dose' then time=cat('P',period,'H48');
	else if VISIT='Post Study' then time='post';
	else if VISIT='Unscheduled Treatment Period 1' then time='P1X';
	else if VISIT='Unscheduled Treatment Period 2' then time='P2X';
	else time=.;
run;
*/

/* TO DO: Use nicer labels but maintain order in tables and figures. */ 

%macro tabval(test);
	proc tabulate data=VS;
		where VSPOS='Supine' and VSTEST=&test.;
		class VISIT treat FORM / mlf order=data;
		var VSORRES;
		table 	FORM * VSORRES * (mean std median min max n),
			treat;
		title "supine &test. - values";
	run;
%mend tabval;

/* vital signs - change */

%macro calcdiff(test);
	data temp;
		set VS;
		where VSTEST=&test. and VSPOS='Supine' and not missing(RID) and not missing(period);
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

%macro tabdiff(test);
proc tabulate data=temp;
	class VISIT treat FORM / mlf order=data;
	var diff;
	table 	FORM * diff * (mean std median min max n),
			treat;
	title "supine &test. - change";
run;
%mend;

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

proc summary data=VS nway;
	where not missing(RID) and not missing(period);
	class VSSTRESC RID FORM treat time;
	/*id RID FORM treat;*/
	output out=temp;
run;

proc sort data=temp;
	by time;
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
	where VSSTRESC='NCS' and not missing(RID) and not missing(FORM) and VSPOS='Supine';
	keep VISIT RID treat period FORM VSTEST VSPOS VSORRES;
run;

proc transpose data=long out=wide;
	by RID treat period VISIT FORM VSPOS;
	id VSTEST;
	var VSORRES;
run;

%report(wide,title="patients with abnormal NCS - scheduled visits");

/* vital signs - sample identifiers . */

data temp;	
	set VS;
	where VSSTRESC='NCS' and not missing(RID) and not missing(FORM);
run;

proc sql noprint;
  select distinct RID
  into :ids_ncs separated by ','
  from temp;
quit;

/* vital signs - unscheduled visits */

data long;
	set VS;
	if RID in (&ids_ncs.);
	if VISIT in ('Unscheduled Treatment Period 1','Unscheduled Treatment Period 2');
run; 

proc transpose data=long out=wide;
	by RID treat period VISIT VSPOS;
	id VSTEST;
	var VSORRES;
run;

%report(wide,title="patients with abnormal NCS - unscheduled visits");

/* vital signs - trajectory */

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

/*
ISSUE: Define order of time. Format time object.
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
	where not missing(RID) and PAGENAME ne 'ECG';
	class treat EGTEST PAGENAME;
	var EGORRES;
	table EGTEST*EGORRES * (mean std median min max N), treat*PAGENAME;
	title 'ECG during treatment';
run;

/* abnormal ECG results during treatment */

%let visits='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD';
%listncs(code=EG,visit=&visits);

data long;
	set EG;
	if RID in (&ids_ncs);
	if VISIT in ('Treatment Period 1: 30 hrs PD','Treatment Period 2: 30 hrs PD');
run; 

proc sort data=long;
	by RID VISIT PAGENAME;
run;

proc transpose data=long out=wide;
	by RID VISIT PAGENAME;
	id EGTEST;
	var EGORRES;
run;

%report(wide,title="patients with abnormal ECG - treatment period");
/* ISSUE: wrong order of PAGENAME levels */

/* abnormal ECG results post study (CONTINUE HERE) */

%listncs(code=EG,visit='Post Study');

data long;
	set EG;
	if RID in (&ids_ncs);
	if VISIT in ('Post Study');
run; 

proc sort data=long;
	by RID VISIT PAGENAME;
run;

proc transpose data=long out=wide;
	by RID VISIT PAGENAME;
	id EGTEST;
	var EGORRES;
run;

%report(wide,title="patients with abnormal ECG - treatment period");

/* adverse events */ 

proc report data=AE spanrows;
	column RID AETERM AESEV AEACN1 AEOUT AEREL AEREL1;
	define RID/order;
	title 'adverse events';
run;

/*--- PHARMACOKINETICS ---*/ 

/* https://www.pharmasug.org/proceedings/2023/SA/PharmaSUG-2023-SA-284.pdf */

filename temp "&pathPhar.\0131FRM18_Flucytosine_20230314.csv";
proc import datafile=temp
		out=PK
		dbms=csv;
run;

data PK;
	set PK;
	rename SUBJECTID=RID;
	rename SAMPLETIME__HR_=SAMPLETIME;
	if SAMPLETIME__HR_='Pre-dose (0)' then SAMPLETIME__HR_=0;
	if CONCENTRATION='BLQ' then CONCENTRATION=0;
	if CONCENTRATION='NS' then CONCENTRATION=.; /* verify this */
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
	output out=PK_mean mean=meanconc;
run;

data PK_mean;
	set PK_mean;
	if not missing(SAMPLETIME) and not missing (treat);
run;

/*ods pdf file="&pathOut.\mixedmodel.pdf";
run;*/
proc sgplot data=PK_mean;
	series x=SAMPLETIME y=meanconc / group=treat markers;
    title 'concentration against time by treatment';
    xaxis label='time';
    yaxis label='concentration';
    keylegend / title='treatment';
run;
/*ods pdf close;*/

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

*/

proc import datafile="I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-02-CM (fed study)\9 - Final analysis\Data\Final Parameters_NCA_primary analysis"
	out=PKpars
	dbms=xls;
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

%add_treat(PKpars);

data PKpars;
 	set PKpars;
	logCmax = log(Cmax);
	logAUCall = log(AUCall); /* multiple choices - check Anouk's code */
	logAUCinf = log(AUCINF_obs); /* multiple choices - check Anouk's code */ 
run;

/* mixed model */

%macro PKmixmod(outcome);
	proc mixed data=PKpars;
		Class subjectid seqence period trt;
		Model &outcome.= seqence period trt /ddfm =kr;
		Random subjectid(seqence) /type=vc;
		lsmeans trt/cl alpha=0.10;
		Estimate 'diff B-A' trt -1 1/cl alpha = 0.10;
		ods exclude CovParms ConvergenceStatus ClassLevels Dimensions Estimates FitStatistics IterHistory LSMeans ModelInfo NObs Tests3;
		ods output CovParms=random Tests3=fixed LSMeans=means Estimates=diff;
	run;
	proc print data=random;
		id CovParm;
		var Estimate;
		title "&outcome.";
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
		id trt;
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
%mend PKmixmod;

%PKmixmod(logCmax);
%PKmixmod(logAUCall);
%PKmixmod(logAUCinf);



/*
TO DO:
- mixed models: combine tables

- vital signs: solve date/time issue

*/

/*
Mann-Whitney U test

proc npar1way data=PKpars wilcoxon;
	class treat;
	var Cmax Tmax Lambda_z;
run;
*/


/*
Saving output to PDF or RTF:
ods pdf file="&pathOut.\mixedmodel.pdf" style=journal;
run;
SOME CODE
ods pdf close;
*/

/*
TRYING TO REFORMAT OUTPUT FROM TABULATE:
Use SAS-proc-tabulate for statistical reporting:
https://support.sas.com/resources/papers/proceedings13/289-2013.pdf

proc tabulate data=sashelp.class out=temp;
  	var age height weight;
  	class sex;
  	table height='height: mean (std)', (sex all)*(mean='' std='');
	table height='height: min-max', (sex all)*(min='' max='');
	table weight='weight: mean (std)', (sex all)*(mean='' std='');
	table weight='weight: min-max', (sex all)*(min='' max='');
run;
*/

/*
proc print data=sashelp.class(obs=10); 
run;

proc format; 
	value 	weightF 	low-80='red' 
						80-130='white' 
						130-high='red';
	value	heightF 	low-60='red'
						60-70='white'
						70-high='red';
	value 	weightM 	low-80='blue' 
						80-130='white' 
						130-high='blue';
	value	heightM 	low-60='blue'
						60-70='white'
						70-high='blue';
run; 

proc report data=sashelp.class nowd; 
	columns Name Sex Age Height Weight; 
	define height/style={background=heightF.};
	define weight/style={background=weightM.}; 
run;

proc report data=sashelp.class nowd;
    columns Name Sex Age Height Weight;
    compute before Sex;
        if Sex = 'F' then do;
            call define('height', 'style', 'style=[background=heightF.]');
            call define('weight', 'style', 'style=[background=weightF.]');
        end;
        else if Sex = 'M' then do;
            call define('height', 'style', 'style=[background=heightM.]');
            call define('weight', 'style', 'style=[background=weightM.]');
        end;
    endcomp;
run;
*/

/*
proc tabulate data=sashelp.class out=temp;
  	var age height weight;
  	class sex;
  	table height='height: mean (std)', (sex all)*(mean='' std='');
	table height='height: min-max', (sex all)*(min='' max='');
	table weight='weight: mean (std)', (sex all)*(mean='' std='');
	table weight='weight: min-max', (sex all)*(min='' max='');
run;

proc tabulate data=sashelp.class out=temp;
  	var age height weight;
  	class sex;
  	table height='height: mean (std)'*(mean=' ' std=' ')
	      height='height: min-max'*(min=' ' max=' ')
	      weight='weight: mean (std)'*(mean=' ' std=' ')
 	      weight='weight: min-max'*(min=' ' max=' ')
          ,
           (sex all);
run;
*/


/* 

macro - listing abnormal

data temp;	
	set VS;
	where VSSTRESC='NCS' and not missing(RID);
run;

proc sql noprint;
  select distinct RID
  into :ids_ncs separated by ','
  from temp;
quit;

data long;
	set VS;
	if RID in (&ids_ncs);
	if VISIT in ('Unscheduled Treatment Period 1','Unscheduled Treatment Period 2');
run; 

proc transpose data=long out=wide;
	by RID VISIT VSPOS period treat;
	id VSTEST;
	var VSORRES;
run;

proc print data=wide;
	id RID;
	var VISIT period treat VSPOS Systolic_Blood_Pressure Diastolic_Blood_Pressure Pulse_Rate;
	title 'patients with abnormal NCS - unscheduled visits';
run;

*/

/* table with special formatting - working 

%macro combine(dataset);
data &dataset.;
	set &dataset.;
	length M_STD MIN_MAX $15;
	M_STD= strip(put(mean, 6.2))||' ('||strip(put(std, 6.2))||')';
	MIN_MAX= strip(put(min, best.))||' - '||strip(put(max, best.));
run;
%mend combine;

proc means data=sashelp.class;
ways 1;
class sex;
var height weight;
output out=means1;
title 'proc means';
run;

proc print data=means1;
run;

proc transpose data=means1 out=wide1;
by sex;
var height weight;
id _stat_;
proc print;
title 'proc transpose';
run;

proc means data=sashelp.class;
var height weight;
output out=means2;
title 'proc means';
run;

proc transpose data=means2 out=wide2;
by _type_;
var height weight;
id _stat_;
proc print;
title 'proc transpose';
run;

%combine(wide1);
%combine(wide2);

proc print data=wide1;
run;

proc sort data= wide1;
by _name_;
run;

proc print data=wide;
run;

proc transpose data=wide1 out=narrow1;
by _name_ ;
var m_std min_max n;
id sex;
proc print;
title 'transpose';
run;

proc transpose data=wide2 out=narrow2 (rename=(col1=TOTAL));
by _name_ ;
var m_std min_max n;
proc print;
title 'transpose';
run;

data final;
merge narrow1 narrow2;
by _name_;
if find(f, '(') gt 0 then stat= 'mean (std)';
else do; stat= 'min - max';
_name_='';
end;
proc print;
title 'final';
run;

proc report data= final split='~';
column _name_ stat('Sex' f m) ('Both~' total);
define _name_/'' display;
define stat/'' display;
define f/ 'F' display;
define m/'M' display;
define total/'' display;
run;

end trial */

/* trial: output from tabulate 

proc tabulate data=sashelp.class out=temp;
	class sex;
	var height weight;
	table (height weight) * (mean median min max), sex all=both;
run;

proc print data=temp;
run;
*/

/* trial: output from summary 

proc summary data=sashelp.class mean std median min max print;
	class sex;
	var height weight;
	output out=temp mean= median= min= max=;
run;

proc print data=temp;
	title 'summary';
run;

proc sort data=temp;
	by _stat_;
run;

proc transpose data=temp;
	by _stat_;
	var height weight;
	id sex;
run;

*/


/* start temporary

proc contents data=wide out=vars noprint;
run;

proc print data=vars;
run;

proc report data=wide spanrows out=temp1;
	compute Temperature;
		call define(_col_,'style','style={background=temp.}');
	endcomp;
	define RID/group;
	define VISIT/group;
	define _NAME_/noprint;
	title "blabla";
run;

proc print data=temp1;
run;

end temporary */
 
