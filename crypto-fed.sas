
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
   %let code = IE AE DM DS DV SU MH VS EG LB; /* add other abbreviations */
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

proc print data=DV noobs nobyline;
	var seq VISIT FORM DVTERM DVCAT;
	id RID;
	by RID;
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
	title 'Demographics - Summary Statistics with tabulate';
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

/*
proc print data=VS(obs=50);
	title 'vital signs';
run;

%macro vstab(visit,pos,test);
	proc tabulate data=VS;
		where VISIT=&visit and VSPOS=&pos and VSTESTCD=&test;
		class seq VSSTRESC;
		var VSORRES;
		table (VSSTRESC)*(N) (VSORRES)*(mean std median min max N), seq all='both';
		title "&visit &pos &test";
	run;
%mend vstab;

%vstab('Screening Visit','','TEMP');
%vstab('Screening Visit','Supine','SYSBP');
*/

data VS;
	set VS;
	if VSPOS in (' ','.') then VSPOS='N/A';
run;

proc print data=VS;
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

proc print data=EG(obs=10);
run;

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

/* supine blood pressure */

data VS;
	set VS;
	if VISIT='Treatment Period 1: 30 hrs PD' then period='1';
	else if VISIT='Treatment Period 2: 30 hrs PD' then period='2';
	else period = '';
    if period='1' and seq='1 (AB)' then treat='A';
	else if period='1' and seq='2 (BA)' then treat='B';
	else if period='2' and seq='1 (AB)' then treat='B';
	else if period='2' and seq='2 (BA)' then treat='A';
	else treat = '';
run;

proc tabulate data=VS;
	where VSTEST="Systolic Blood Pressure" and VSPOS='Supine';
	class VISIT treat FORM;
	var VSORRES;
	table 	FORM * VSORRES * (mean std median min max n),
			treat;
	title 'systolic';
run;



/* Write macro for above snippet and apply to supine systolic blood pressure, supine diastolic blood pressure and supine pulse rate.*/

/* supine systolic blood pressure, supine diastolic blood pressure, supine pulse rate

/* Calculate change with respect to pre-dose visit.*/


data temp;
	set VS;
	where VSTEST="Systolic Blood Pressure" and VSPOS='Supine' and not missing(RID) and not missing(period);
run;

data trial;
	diffA = .;
  	diffB = .;
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

proc tabulate data=trial;
	class VISIT treat FORM;
	var diff;
	table 	FORM * diff * (mean std median min max n),
			treat;
	title 'systolic';
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

proc print data=PK(obs=10);
	title 'transformed';
run;

data PK;
	set PK;
	if PERIOD=1 and seq='1 (AB)' then treat='A';
	if PERIOD=1 and seq='2 (BA)' then treat='B';
	if PERIOD=2 and seq='1 (AB)' then treat='B';
	if PERIOD=2 and seq='2 (BA)' then treat='A';
run;

%asnumeric(PK,SAMPLETIME);
%asnumeric(PK,CONCENTRATION);

proc print data=pk(obs=100);
	title 'transformed';
run;

proc means data=PK;
run;

/* one separate scatterplot for each sample */

proc sgpanel data=PK noautolegend;
	panelby RID/columns=3 rows=4;
	series x=SAMPLETIME y=CONCENTRATION/group=treat markers;
	title 'concentration against time by treatment';
run;

/* one common scatterplot for all samples */

proc means data=PK;
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
	ods select CovParms Tests3 LSMeans Estimates;
	title 'output from mixed model';
run; 
/*ods pdf close;*/




/*
TO DO LIST:

- Write macro for transforming variables to numerical type if necessary (arguments: code for dataset).

- Write macro for creating table of summary statistics (arguments: code for dataset, variables).
  This macro should identify numerical/categorical variables,
  if necessary first make a table for each variable,
  and then combine the different tables.

- Plot PK values.

- Compute PK parameters in SAS.
*/

