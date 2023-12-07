
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
   %let code = IE AE DM DS DV SU MH VS; /* add other abbreviations */
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

/*ods rtf file="&pathOut.\demographics.rtf";
run;*/
proc tabulate data=DM;
	class seq sex race;
	var age weight height bmi;
	table (age)*(mean median std min max n)
		(sex race)*(n colpctn)
		(weight height bmi)*(mean median std min max n),
		seq all='both';
	title 'Demographics - Summary Statistics with tabulate';
run;
/*ods rtf close;*/

/* alcohol and smoking */

%asnumeric(SU,SUDOSE);

proc print data=SU(obs=20);
run;

%macro tabdrug(type);
	%put &type;
	proc tabulate data=SU out=&type;
		where SUTRT="&type";
		class seq SUTRT SUOCCUR;
		var SUDOSE;
		table (SUOCCUR)*(n)
			(SUDOSE)*(mean std median min max n),
			seq all='both';
		title "&type";
	run;
%mend tabdrug;

%tabdrug(ALCOHOL);
%tabdrug(SMOKER);

/*CONTINUE HERE: COMBINE ROWS, SUCH AS mean (sd) and min-max. */

/* medical history */

proc print data=MH;
	where not missing(RID);
	id RID;
	var seq MHTERM MHSTDAT MHENDAT MHONGO;
	title 'medical history';
run;


/* vital signs */

%asnumeric(VS,VSORRES);

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

