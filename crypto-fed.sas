
/* FED STUDY */

/* clean workspace */

dm 'odsresults; clear';
proc datasets library=work kill;
run;
%symdel _all_;

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

%macro addrid(file); 
data &file;
 	set &file;
 	RID = input(substr(USUBJID,index(USUBJID,'/')+1),best.);
run;
%mend addrid;

/* sort by random ID */

%macro sortrid(file);
	proc sort data=&file;
		by RID;
	run;
%mend sortrid;

/* add random info */

%macro addinf(file);
	data &file;
		merge &file(in=a) random(in=b);
		by RID;
		if a;
	run;
%mend addinf;

/* import and process clinical data */

%macro prepare;
   %let code = IE AE DM DS DV SU MH VS EG LB; /* add other abbreviations*/
   %do i = 1 %to %sysfunc(countw(&code));
      %import(&pathClin,%scan(&code,&i));
	  %addrid(%scan(&code,&i));
	  %sortrid(%scan(&code,&i));
	  %addinf(%scan(&code,&i));
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

/* ineligibility */

proc print data=IE;
	where (IECAT='INCLUSION' and IESTRESC='No') or (IECAT='EXCLUSION' and IESTRESC='Yes');
	var IECAT IETEST IESTRESC;
	id SUBJID;
	title 'listing of ineligible samples';
run;

/* protocol deviations */

proc print data=DV;
	var seq VISIT FORM DVTERM DVCAT;
	id RID;
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
    class seq SUTRT SUOCCUR;
    var SUDOSE;
    table SUTRT * SUOCCUR * n
          SUTRT * SUDOSE *(mean std median min max n),
          seq all='both';
    title "alcohol and smoking";
run;

/* medical history */

proc print data=MH;
	where not missing(RID);
	id RID;
	var seq MHTERM MHSTDAT MHENDAT MHONGO;
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
	class seq VSPOS VSTESTCD VSSTRESC;
	var VSORRES;
	table	VSPOS * VSTESTCD * (VSSTRESC)*(N)
			VSPOS * VSTESTCD * (VSORRES)*(mean std median min max N),
			seq all='both';
	title "vital signs";
run;

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

/* hematology: data formatting will be different in actual clinical trial */

/* vital signs - values */

data VS;
	set VS;
	if VISIT in ('Treatment Period 1: 30 hrs PD','Unscheduled Treatment Period 1') then period='1';
	else if VISIT in ('Treatment Period 2: 30 hrs PD','Unscheduled Treatment Period 2') then period='2';
	else period = '';
    if period='1' and seq='1 (AB)' then treat='A';
	else if period='1' and seq='2 (BA)' then treat='B';
	else if period='2' and seq='1 (AB)' then treat='B';
	else if period='2' and seq='2 (BA)' then treat='A';
	else treat = '';
run;

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

%macro tabval(test);
	proc tabulate data=VS;
		where VSPOS='Supine' and VSTEST=&test;
		class VISIT treat FORM / mlf order=data; /* new: / mlf order=data */
		var VSORRES;
		table 	FORM * VSORRES * (mean std median min max n),
			treat;
		title "supine &test - values";
	run;
%mend tabval;

/* vital signs - change */

%macro calcdiff(test);
	data temp;
		set VS;
		where VSTEST=&test and VSPOS='Supine' and not missing(RID) and not missing(period);
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
	title "supine &test - change";
run;
%mend;

/* vital signs - both */

%tabval("Systolic Blood Pressure");
%calcdiff("Systolic Blood Pressure");
%tabdiff("Systolic Blood Pressure");

%tabval("Diastolic Blood Pressure");
%calcdiff("Diastolic Blood Pressure");
%tabdiff("Diastolic Blood Pressure");

%tabval("Pulse Rate");
%calcdiff("Pulse Rate");
%tabdiff("Pulse Rate");

/* vital signs - normal/abnormal */

proc summary data=VS nway;
	where not missing(RID) and not missing(period);
	class VSSTRESC RID FORM treat time;
	id RID FORM treat;
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
	keep RID treat period FORM VSTEST VSPOS VSORRES;
run;

proc transpose data=long out=wide;
	by RID treat period FORM VSPOS;
	id VSTEST;
	var VSORRES;
run;

proc print data=wide;
	id RID;
	title 'patients with abnormal NCS - scheduled visits';
run;

/* vital signs - sample identifiers . */

data temp;	
	set VS;
	where VSSTRESC='NCS' and not missing(RID) and not missing(FORM) and VSPOS='Supine';
run;

proc sql;
  select distinct RID
  into :ids_ncs separated by ','
  from temp;
quit;

/*%put &ids_ncs;*/

/* vital signs - unscheduled visits */

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
	title 'patients with abnormal NCS - unscheduled visits';
run;

/* vital signs - trajectory */

%macro plotvs(test);
	data temp;
		set VS;
		where VSTEST=&test. and VSPOS='Supine';
		if RID in (&ids_ncs);
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

/* adverse events */ 

proc print data=AE;
	id RID;
	var AETERM AESEV AEACN1 AEOUT AEREL AEREL1;
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
	if SAMPLETIME__HR_='Pre-dose (0)' then SAMPLETIME__HR_=0;
	if CONCENTRATION='BLQ' then CONCENTRATION=0;
	rename SUBJECTID=RID;
	rename SAMPLETIME__HR_=SAMPLETIME;
run;

%addinf(PK);

data PK;
	set PK;
	if PERIOD=1 and seq='1 (AB)' then treat='A';
	if PERIOD=1 and seq='2 (BA)' then treat='B';
	if PERIOD=2 and seq='1 (AB)' then treat='B';
	if PERIOD=2 and seq='2 (BA)' then treat='A';
run;

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
	if PERIOD=1 and seqence=1 then treat='A';
	if PERIOD=1 and seqence=2 then treat='B';
	if PERIOD=2 and seqence=1 then treat='B';
	if PERIOD=2 and seqence=2 then treat='A';
	logCmax = log(Cmax);
	logAUCall = log(AUCall); /* multiple choices - check Anouk's code */
	logAUCinf = log(AUCINF_obs); /* multiple choices - check Anouk's code */ 
run;

/* mixed model */

/*ods pdf file="&pathOut.\mixedmodel.pdf" style=journal;
run;*/
proc mixed data=PKpars;
	Class subjectid seqence period trt;
	Model logCmax= seqence period trt /ddfm =kr;
	Random subjectid(seqence) /type=vc;
	lsmeans trt/cl alpha=0.10;
	Estimate 'diff B-A' trt -1 1/cl alpha = 0.10;
	ods exclude CovParms ConvergenceStatus ClassLevels Dimensions Estimates FitStatistics IterHistory LSMeans ModelInfo NObs Tests3;
	title 'output from mixed model';
	ods output CovParms=random Tests3=fixed LSMeans=means Estimates=diff;
run; 
/*ods pdf close;*/

proc print data=random;
	id CovParm;
	var Estimate;
	title 'random';
run;

proc print data=fixed;
	id Effect;
	var FValue ProbF;
	title 'fixed';
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
	title 'means';
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
	title 'diff';
run;

/* TO DO: mixed models: combine tables, write macro, apply macro*/ 

/* TO DO: vital signs: solve date/time issue */ 

/* TO DO: general: Extract output from tabulate */
