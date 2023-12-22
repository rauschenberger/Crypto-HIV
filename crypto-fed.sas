
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

%macro color(name);
	%put name: &name.;
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

/* vital signs - screening - listing */

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
		define RID/order;
		define VISIT/order;
		define _NAME_/noprint;
		title &title.;
	run;
%mend;

%listncs(code=VS,visit='Screening Visit');
%showncs(code=VS,visit='Screening Visit' 'Unscheduled Screening',name='VS');
%report(wide,title="patients with abnormal NCS - screening visits",name='VS');

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
	where VSSTRESC='NCS' and not missing(RID) and VISIT in ('Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD');
run;

proc sort data=VS;
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
%showncs(code=EG,visit='Treatment Period 1: 30 hrs PD' 'Treatment Period 2: 30 hrs PD',name='EG');
%report(wide,title="patients with abnormal ECG - treatment period",name='EG');

/* ISSUE: wrong order of PAGENAME levels */

/* abnormal ECG results post study (CONTINUE HERE) */

%listncs(code=EG,visit='Post Study');
%showncs(code=EG,visit='Post Study',name='EG');
%report(wide,title="patients with abnormal ECG - treatment period",name='EG');

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

Things to do:

- mixed models: combine tables
- vital signs: solve date/time issue
- order labels for category levels
- security analysis
- integration with WinNonlin


Mann-Whitney U test:

proc npar1way data=PKpars wilcoxon;
	class treat;
	var Cmax Tmax Lambda_z;
run;


Saving output to PDF or RTF:

ods pdf file="&pathOut.\mixedmodel.pdf" style=journal;
run;
SOME CODE
ods pdf close;

*/
