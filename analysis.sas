
/******************************************************************************/
/*** Crypto-HIV phase II study  ***********************************************/
/*** Armin Rauschenberger *****************************************************/
/******************************************************************************/

/*
Remaining issues

Franck (2026-05-18):
- Tables with Yes/No should only show the counts for 'YES' and indicate in a footnote that there a no missing values.
- Similarly, tables with Normal/Abnormal should only show the counts for 'Abnormal' and include a footnote.
- Tables with separate blocks for numerical and categorical variables should be split into two tables.
- Medical history: Reported term and other term should be combined into one column.
- Adverse events: Relation to arm 1 and to arm 2 should be combined into one column.
- Concomitant medication: Ongoing='Yes' could be moved to the enddate column (i.e., enddate = 'ongoing').
- Physical examination: Define abbreviations in a footnote (e.g., HEENT).
- Clinical chemistry (and others): Show unscheduled visit only if there is at least one non-missing value.

Michel (2026-05-20):
- Symptoms: medical coding and table per system organ class and preferred term?
- Adverse events: idem and maybe one table of “at least one AE per patient” but let’s see if they request it
- Vital signs: body temp has only the “N” line
- Urinalysis: Variable name appear in the column “Result” sometimes i.e. “Laboratory Test”, 
- Figures: the unit is missing in the X-axis title

Armin
- The entry "D" means "not done" and the entry "A" means "not applicable". Replace both by NA!
- Data set PE variable PEORRES should have the possible values "Normal", Abnormal, NCS" and "Abnormal, CS" but also has the value "D".
- PC: Combine two columns on reasons! The second one is currently empty but might contain data in the future.
- continue discussion on data corrections
- do not overwrite variables when bringing values to the same unit
- check NCS and CS in LB_LABORATORY
- The dataset on drug accountability is empty. It does not contain any information on taken and remaining amounts.
*/

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

%include "code/setup.sas";
%include "code/macros.sas";
%include "code/format.sas";
%include "code/import.sas";

%global table_n figure_n listing_n;
%let table_n   = 0; %let figure_n  = 0; %let listing_n = 0; title;
ods document name=tables(write); ods document close;
ods document name=figures(write); ods document close;
ods document name=listings(write); ods document close;

%include "code/tlf_dm.sas"; /* demographics */
%include "code/tlf_mh.sas"; /* medical history */
%include "code/tlf_pm.sas"; /* prior medications */
%include "code/tlf_ie.sas"; /* ineligibility */
%include "code/tlf_dv.sas"; /* protocol deviations */
%include "code/tlf_ds.sas"; /* disposition milestones */
%include "code/tlf_di.sas"; /* discharge */
%include "code/tlf_art.sas"; /* ART initiation */
%include "code/tlf_artt.sas"; /* ART treatment */
%include "code/tlf_ex.sas"; /* treatment exposure */

/******************************************************************************/
/* * Subsection 4.X: drug accountability * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

/*
The dataset on drug accountability is empty.
It does not contain any information on taken and remaining amounts.

%put --- drug accountability ---;

proc report data=DA;
run;
*/

/******************************************************************************/
/* * Subsection 4.X: concomitant medications * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- concomitant medications ---;

%label_vars(code=CM);

data CM;
	set CM;
	Dosing = catx('',CMDOSE,CMDOSU_LIB) || ' (' || strip(CMDOSFRQ) || ', ' || strip(CMROUTE_LIB) || ')';
run;

ods document name=listings(update);
proc report data=CM spanrows style(report)=[width=100%] style(column)=[cellwidth=12.4%] style(header)=[cellwidth=12.4%];
	%title(type="listing",label='Concomitant Medications');
	column USUBJID CMINDC CMTRT ATC_CLASSIFICATION_NAME Dosing CMSTDTC CMENDTC CMONGO;
	define USUBJID/order;
run;
ods document close;

/******************************************************************************/
/* * Subsection 4.X: current symptoms* * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- current symptoms ---;

%order_levels(code=CE,var=VISIT);
%label_vars(code=CE);

ods document name=tables(update);
proc tabulate data=CE;
	%title(type="table",label="Current Symptoms");
	title2 '(number of patients by visit and treatment)';
	class VISIT treatment CETERM / order=internal;
	table VISIT * CETERM * (n rowpctn='%'),
			treatment all='Total';
run;
ods document close;

/******************************************************************************/
/* * Subsection 4.X: adverse events * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- adverse events ---;

%order_levels(code=AE,var=AESEV);
%label_vars(code=AE);

data AE;
	set AE;
	if AEREL in ('A') then AEREL='';
	if AEREL1 in ('A') then AEREL1='';
run;

ods document name=tables(update);
proc tabulate data=AE;
	%title(type="table",label="Number Adverse Events");
	title2 '(by type and treatment)';
	class treatment AETERM;
	table AETERM='' * (n),
		treatment all='Total';
run;
ods document close;

ods document name=tables(update);
proc tabulate data=AE;
	%title(type="table",label="Number of Adverse Events");
	title2 '(by severity and treatment)';
	class AESEV treatment/order=internal;
	table AESEV * (n rowpctn='%'), treatment all='Total';
run;
ods document close;

ods document name=listings(update);
proc report data=AE spanrows style(report)=[width=100%] style(column)=[cellwidth=9.8%] style(header)=[cellwidth=9.8%];
	%title(type="listing",label='All Adverse Events');
	%color(name=AE);
	column USUBJID AETERM AESEV_ PT System_Organ_Class AEACN1 AEOUT AEREL AEREL1 treatment;
	define USUBJID/order;
run;
ods document close;

ods document name=listings(update);
proc report data=AE spanrows style(report)=[width=100%] style(column)=[cellwidth=9.8%] style(header)=[cellwidth=9.8%];
	where AESEV_ not in ('Mild','Moderate');
	%title(type="listing",label='Severe or Life-Threatening Adverse Events');
	%color(name=AE);
	column USUBJID AETERM AESEV_ PT System_Organ_Class AEACN1 AEOUT AEREL AEREL1 treatment;
	define USUBJID/order;
run;
ods document close;

/******************************************************************************/
/* * Subsection 4.X: physical examination* * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- physical examination ---;

%label_vars(code=PE);

data PE_sub;
	retain USUBJID VISIT PETESTCD PEORRES PEORRES_SP;
	set PE(keep=USUBJID VISIT PETESTCD PEORRES PEORRES_SP);
	if PEORRES='D' then PEORRES='';
	where not missing(PEORRES) and PEORRES not in ('Normal','','D');
run;

ods document name=listings(update);
%report(data=PE_sub,title='Physical Examination with Abnormal Results',name=PE);
ods document close;

/******************************************************************************/
/* * Subsection 4.X: vital signs * * * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- vital signs ---;

data VS;
	set VS;
	if VSPOS in (' ','.') then VSPOS='N/A';
	if VSSTRESC in (' ','.') then VSSTRESC='N/A';
	where VSTEST not in ('Weight','Height','Body Mass Index');
run;

%order_levels(code=VS,var=VISIT);
/*%order_levels(code=VS,var=VSTEST);*/
%order_levels(code=VS,var=VSSTRESC);
/*%order_levels(code=VS,var=time);*/
%as_numeric(code=VS,var=VSORRES);
/*%sub_per(code=VS);*/
%add_unit(code=VS);
%label_vars(code=VS);

/* table: vital signs at screening visit by treatment */ 
ods document name=tables(update);
%tabulate(code=VS,visit="Screening");
ods document close;

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
ods document name=listings(update);
%list_abnormal(code=VS,check_visit='Screening',show_visit='Screening' 'Unscheduled',width=8%);
ods document close;

/* tables: values of and change in vital signs*/
ods document name=tables(update);
%process_table(code=VS,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg)|Pulse Rate (beats/min)|Respiratory Rate (beats/min)|Oxygen Saturation (%)); /* per */
ods document close;

/*table: count of abnormal values */

proc summary data=VS nway;
	where not missing(RID);
	class VSSTRESC VSTEST RID VISIT treatment;
	output out=temp;
run;

ods document name=tables(update);
proc tabulate data=temp;
	%title(type="table",label='Count and Percentage of Normal, NCS or CS Abnormal Vital Signs');
	title2 '(by visit, vital sign, and treatment)';
	where not missing(RID);
	class VISIT treatment VSTEST VSSTRESC RID / order=internal;
	table VISIT * VSTEST * VSSTRESC * (n pctn<VSSTRESC>='%'),
		  treatment;
run;
ods document close;

/* listing: abnormal during treatment */
ods document name=listings(update);
%list_abnormal(code=VS,check_visit=&treat_days.,show_visit=&treat_days. &post_weeks.);
ods document close;

/* figures: trajectories of patients with abnormal values */
ods document name=figures(update);
%process_traject(code=VS,check_visit=&treat_days.,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg))
ods document close;

/* figures: mean values and mean change */
ods document name=figures(update);
%process_trend(code=VS,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg)|Pulse Rate (beats/min)) /* per */
ods document close;

/* vital signs post study, by treatment */
ods document name=tables(update);
%tabulate(code=VS,visit="Week 10");
ods document close;

/******************************************************************************/
/* * Subsection 4.X: Glasgow coma score* * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- coma score ---;

%order_levels(code=GC,var=VISIT);
%as_numeric(code=GC,var=GCS_TOTAL);
%label_vars(code=GC);

data GC;
	set GC;
	length GCS_max $5;
	if GCSPERF='Yes' then do;
		if GCS_TOTAL=15 then GCS='=15';
		else GCS='<15';  
	end;
	else do;
		GCS='N/A';
	end;
run;

ods document name=tables(update);
proc tabulate data=GC;
	%title(type="table",label="Glasgow Coma Scale - Fully Awake Patients");
	title2 '(by visit and treatment)';
	class VISIT GCS treatment / order=internal;
	table VISIT * GCS * (n pctn<GCS>='%'),
			treatment all='Total';
run;
ods document close;

data GC_sub;
  	retain USUBJID VISIT GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE GCS_TOTAL;
	set GC(keep=USUBJID VISIT GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE GCS_TOTAL);
	where GCSPERF="Yes"; /*and GCS_TOTAL < 15*/
	drop GCSPERF;
run;

ods document name=listings(update);
%report(data=GC_sub,title='Glasgow Coma Scale',name=GC);
ods document close;

/******************************************************************************/
/* * Subsection 4.X: lumbar punctures* * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- lumbar punctures ---;

/*
%prepare;

proc report data=LP;
run;
*/

data LP;
	set LP;
	if LPORRES in ('1+') or LPTEST in ('CSF samples','Candida Spp','Cryptococcus neoformans','E. coli','Mycobacterium tuberculosis','Neisseria meningitidis','Streptococcus pneumoniae') then do;
		LPORRES_numeric = '';
		LPORRES_ordinal = LPORRES;
	end;
	else do;
		LPORRES_numeric = LPORRES;
		LPORRES_ordinal = '';
	end;
	LPORRES=LPORRES_numeric;
run;

%add_unit(code=LP);
%as_numeric(code=LP,var=LPORRES_numeric); /* some values are semi-quantitative */ 
%label_vars(code=LP);

%macro tabulateLP(visit=);
	proc tabulate data=LP; /*(where=(VISIT=&visit. and not missing(LPORRES_numeric)))*/
		%title(type="table",label="Lumbar Punctures at %sysfunc(dequote(&visit.)) Visit - Numerical Variables");
		var LPORRES_numeric;
		class VISIT treatment LPTEST;
		where VISIT=&visit. and not missing(LPORRES_numeric);
		table LPTEST * LPORRES_numeric='' * (mean median std min max n),
		treatment all='Total';
	run;
	proc tabulate data=LP; /*(where=(VISIT=&visit. and not missing(LPORRES_ordinal)))*/
		%title(type="table",label="Lumbar Punctures at %sysfunc(dequote(&visit.)) Visit - Ordinal Variables");
		class VISIT treatment LPTEST LPORRES_ordinal;
		where VISIT=&visit. and not missing(LPORRES_ordinal);
		table LPTEST * LPORRES_ordinal='' * (n),
			treatment all='Total';
	run;
	/*
	proc tabulate data=LP;
		%title(type="table",label="Lumbar Punctures at %sysfunc(dequote(&visit.)) Visit - All Variables");
		var LPORRES_numeric;
		class VISIT treatment LPTEST LPORRES_ordinal;
		where VISIT=&visit.;
		table 	LPTEST * LPORRES_numeric='' * (mean median std min max n)
				LPTEST * LPORRES_ordinal * (n),
				treatment all='Total';
	run;
	*/
%mend tabulateLP;

%macro processLP(visits=);
    %let n = %sysfunc(countw(&visits., |));
    %do i = 1 %to &n.;
        %let visit = %scan(&visits., &i., |);
        %tabulateLP(visit="&visit.");
    %end;
%mend processLP;

ods document name=tables(update);
%processLP(visits=Day 1|Day 3|Day 7|Day 15);
ods document close;

/******************************************************************************/
/* * * Subsection 4.X: laboratory* * * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- laboratory ---;

data LB;
	set LB;
	length temp $60;
	if missing(LBCLSIG) then do;
		temp = 'Normal';
	end;
	else do
		temp = LBCLSIG;
	end;
	drop LBCLSIG;
	rename temp=LBCLSIG;
run;

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
	else if LBTEST = 'Neutrophils' then do;
		if LBORRESU = '109/L' then do;
			LBORRES = LBORRES * 1000;
			LBORRESU = 'cells/uL';
		end;
	end;
	else if LBTEST = 'Leucocytes' then do;
		if LBORRESU = '109/L' then do;
			LBORRES = LBORRES * 1000;
			LBORRESU = 'cells/uL';
		end;
	end;
run;

/*%sub_per(code=LB);*/
%add_unit(code=LB);
%label_vars(code=LB);

%macro process_LB(types=,visits=);
	%local i type j visit width;
	%do j = 1 %to %sysfunc(countw(&visits, |));
        %let visit = %scan(&visits, &j, |);
		%do i = 1 %to %sysfunc(countw(&types, |));
  			%let type = %scan(&types, &i, |);
			ods document name=tables(update);
  			%tabulate(code=LB,type="&type",visit="&visit");
			ods document close;
		%end;
	%end;
	%do i = 1 %to %sysfunc(countw(&types, |));
		%let type = %scan(&types, &i, |);
		%if &type. = Clinical Chemistry %then %let width = 8.3%;
        %else %if &type. = Hematology   %then %let width = 9.9%;
		ods document name=listings(update);
		%list_abnormal(code=LB,type="&type",check_visit='Screening',show_visit='Screening' 'Unscheduled',width=&width.);
		ods document close;
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

ods document name=listings(update);
%list_abnormal(code=LB_temp,type="Urianalysis",check_visit='Screening',show_visit='Screening' 'Unscheduled',width=8.1%);
ods document close;

%macro tabulate_urine(visit=);
	proc tabulate data=LB;
		%title(type="table",label="Urinalysis at %sysfunc(dequote(&visit.)) Visit - Numerical Variables");
		title2 '(top: number and percentage of normal, NCS abnormal, and CS abnormal values';
		title3 'bottom: summary statistics of numerical values)';
		where type='Urianalysis' and VISIT_=&visit.;
		var LBORRES_numeric;
		class treatment VISIT_ LBTEST LBCLSIG;
		table	LBTEST * LBCLSIG * (n pctn<LBCLSIG>='%')
			LBTEST * LBORRES_numeric='' * (mean std median min max n),
			treatment all='Total';
	run;
	proc tabulate data=LB;
		%title(type="table",label="Urinalysis at %sysfunc(dequote(&visit.)) Visit - Ordinal Variables");
		title2 '(top: number and percentage of normal, NCS abnormal, and CS abnormal values';
		title3 'bottom: counts and percentages of ordinal variables)';
		where type='Urianalysis' and VISIT_=&visit.;
		class treatment VISIT_ LBTEST LBCLSIG LBORRES_ordinal;
		table	LBTEST * LBCLSIG * (n pctn<LBCLSIG>='%')
			LBTEST * LBORRES_ordinal * (n pctn<LBORRES_ordinal>='%'),
			treatment all='Total';
	run;
%mend tabulate_urine;

ods document name=tables(update);
%tabulate_urine(visit='Screening');
%tabulate_urine(visit='Day 15');
ods document close;

/* infection tests*/ 

ods document name=tables(update);
proc tabulate data=LB;
	%title(type="table",label='Infection Tests at Screening Visit');
	title2 "(summary statistics for numerical variables)";
    where type='HIV Test' and VISIT_='Screening' and LBORRES is not missing;
    var LBORRES;
    class VISIT_ treatment LBTEST;
    table LBTEST * LBORRES * (mean std median min max n),
          treatment all='Total';
run;
proc tabulate data=LB;
	%title(type="table",label='Infection Tests at Screening Visit');
	title2 "(counts and percentages for binary variables)";
    where type='HIV Test' and VISIT_='Screening' and LBSTNRC is not missing;
    class VISIT_ treatment LBTEST LBSTNRC;
    table LBTEST * LBSTNRC * (n pctn<LBSTNRC>='%'),
          treatment all='Total';
run;
ods document close;

/* Switch to showing those with CS only?*/ 

/* tables: */ 

ods document name=tables(update);
%process_table(code=LB,tests=Haemoglobin (g/dL)|Leucocytes); /* per */
ods document close;

/* */ 
ods document name=figures(update);
%process_trend(code=LB,tests=Haemoglobin (g/dL)|Leucocytes); /* per */
ods document close;

/* */ 
ods document name=figures(update);
%process_traject(code=LB,check_visit=&treat_days.,tests=Haemoglobin (g/dL)|Leucocytes); /* per */
ods document close;


/*
Problem with units:
data temp;
	set LB;
	where not missing(LBORRES);
run;

proc freq data=temp;
    tables LBTEST;
run;
*/

/******************************************************************************/
/* * Subsection 4.X: electrocardiogram * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- electrocardiogram ---;

%order_levels(code=EG,var=VISIT);
%order_levels(code=EG,var=EGSTRESC1);
/*%order_levels(code=EG,var=EGTEST);*/
%as_numeric(code=EG,var=EGORRES);
/*%sub_per(code=EG);*/
%add_unit(code=EG);
%label_vars(code=EG);

/* table: electrocardiogram, at day 1*/ 
ods document name=tables(update);
%tabulate(code=EG,visit="Day 1");
ods document close;

/* listing: abnormal EG at day 1*/
ods document name=listings(update);
%list_abnormal(code=EG,check_visit='Day 1',show_visit='Day 1');
ods document close;

/******************************************************************************/
/* * Subsection 4.X: Rankin disability questionnaire * * * * * * * * * * * * */
/******************************************************************************/

%put --- disability ---;

%order_levels(code=RANKIN,var=VISIT);
%as_numeric(code=RANKIN,var=RANKIN_GRADE);
%label_vars(code=RANKIN);

ods document name=tables(update);
proc tabulate data=RANKIN;
	%title(type="table",label="Rankin Disability Questionnaire");
	title2 '(top: categorical variables, bottom: ordinal variable)';
	var RANKIN_GRADE;
	class VISIT treatment LPPERF RANKIN_Q1 RANKIN_Q2 / order=internal;
	table 	VISIT * (LPPERF='lumbar puncture' RANKIN_Q1='Q1 (daily help)' RANKIN_Q2='Q2 (other problems)') * (n pctn<LPPERF RANKIN_Q1 RANKIN_Q2>='%')
			VISIT * RANKIN_GRADE='grade' * (mean median std min max n),
			treatment all='Total';
run;
ods document close;

/******************************************************************************/
/* * Subsection 4.X: death details * * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- death details ---;

%order_levels(code=DD,var=VISIT);
%label_vars(code=DD);

ods document name=tables(update);
proc tabulate data=DD;
	%title(type="table",label="Death Details");
	class VISIT treatment DSSTATUS / order=internal;
	table VISIT * DSSTATUS * (n pctn<DSSTATUS>='%'), treatment all='Total';
run;
ods document close;

ods document name=listings(update);
proc report data=DD;
	%title(type="listing",label='Death Details');
	where not missing(DSSTATUS) and DSSTATUS ne "Alive";
run;
ods document close;

/******************************************************************************/
/* * Subsection 4.X: pregnancy * * * * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- pregnancy ---;

%order_levels(code=PR,var=VISIT);
%label_vars(code=PR);

ods document name=tables(update);
proc tabulate data=PR;
	%title(type="table",label="Pregnancy Rapid Urine Test");
	title2 '(by visit and treatment)';
	class VISIT treatment PREGORRES / order=internal;
	table VISIT * PREGORRES * (n pctn<PREGORRES>='%'),
			treatment all='Total';
run;
ods document close;

data PR_sub;
	retain USUBJID VISIT PREGPERF PREGORRES;
	set PR(keep=USUBJID VISIT PREGPERF PREGORRES);
run;

ods document name=listings(update);
%report(data=PR_sub,title='Pregnancy Tests and Results',name=PR);
ods document close;

/******************************************************************************/
/* * Subsection 4.X: quality of life * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- quality of life ---;

%label_vars(code=EQ);

ods document name=listings(update);
proc report data=EQ;
	%title(type="listing",label="Quality of Life (EQ-5D-3L)");
	column USUBJID VISIT treatment MOBILITY SELFCARE USUALACTIVITIES PAINDISCOMFORT ANXIETYDEPRESSION SCALE;
	where not missing(MOBILITY) or not missing(SELFCARE) or not missing(USUALACTIVITIES) or not missing(PAINDISCOMFORT) or not missing(ANXIETYDEPRESSION) or not missing (SCALE);
run;
ods document close;

/******************************************************************************/
/* * Subsection 4.X: palatability acceptability* * * * * * * * * * * * * * * */
/******************************************************************************/
 
%put --- palatability ---;

%label_vars(code=QUEST);

/*
Find a more compact way of presenting this.
proc report data=QUEST;
	%title(type="listing",label='palatability acceptability');
run;
*/

/*
proc tabulate data=QUEST;
	class VISIT treatment PARTICIPANT_Q1 PARTICIPANT_Q2;
	table VISIT * (PARTICIPANT_Q1 PARTICIPANT_Q2), treatment all='Total';
run;
*/
	
/* CONTINUE HERE: tabulate with different levels for each variable? */ 

/******************************************************************************/
/* * Subsection 4.X: pharmacokinetics * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- pharmacokinetics ---;

%order_levels(code=PC,var=PC_SAMPLING_TIME);
%as_numeric(code=PC,var=PC_DELAY);
%label_vars(code=PC);

ods document name=tables(update);
proc tabulate data=PC;
	%title(type="table",label="Calculated Delay in Blood Sampling for Pharmacokinetics");
	title2 '(in minutes, by visit and treatment)';
	class VISIT PC_SAMPLING_TIME treatment /order=internal;
	var PC_DELAY;
	table VISIT * PC_SAMPLING_TIME * PC_DELAY='' * (mean median std min max n), treatment all="total";
run;
ods document close;

data PC;
	set PC;
	if VISIT in ('Day 1','Day 2') then do;
		idv = cats(RID,'_one');
	end;
	else if VISIT in ('Day 6','Day 7') then do;
		idv = cats(RID,'_two');
	end;
run;

data temp;
	set PC;
	where not missing(PC_DELAY) and (PC_DELAY < -20 or PC_DELAY > 20);
run;

proc sql noprint;
	select distinct quote(trim(idv),"'")
	into :idv_delay separated by ','
	from temp;
quit;

ods document name=listings(update);
proc report data=PC spanrows;
	%color(name=PC);
	%title(type="listing",label="Patients with a PK Blood Sampling Deviation");
	title2 '(patients on days 1/2 or 6/7 with <-20 or >20 minutes)'; 
	columns USUBJID VISIT PC_SAMPLING_TIME PCTPTREF PCDTC PC_DEVIATION PC_DELAY PC_DELAY_RSN ;
	where idv in (&idv_delay.);
	define USUBJID/order;
	define VISIT/order;
run;
ods document close;


title ' ';
options nodate nonumber;
ods escapechar='^';
ods pdf file="&pathOut.\\myfile.pdf" style=printer startpage=yes;
ods pdf text="^S={just=c font_size=24pt font_weight=bold} ^10n 5FC HIV-Crypto";
ods pdf text="^S={just=c font_size=24pt} ^1n Tables, Figures, and Listings";
ods pdf text="^S={just=c font_size=14pt} ^10n Armin Rauschenberger";
ods pdf text="^S={just=c font_size=14pt} ^1n %sysfunc(today(), worddate.)";
ods pdf text="^S={just=c font_size=14pt} ^5n ";

proc odstext;
	h1 "Disclaimer";
	p  "^{style [color=red fontweight=bold] Problems in the datasets (see below) have not yet been fixed.}";
	p  "^{style [color=red fontweight=bold] Reference ranges (VS, EG, and LB) and conversion factors (LB) have not yet been provided.}";
	p  "^{style [color=red fontweight=bold] The SAS code has not yet been double-checked.}";
run;

ods text="Please add text directly to the source code (.sas) and not to the compiled document (.pdf or .docx). Otherwise each update in the data or the code will erase the text.";

ods pdf startpage=now;

proc odstext;
	h1 "Data Issues";
	p  "Leucocytes has either LBORRESU equal to 109/L or cells/uL or a free-text comment in LBCO (multiple variants of 10e3/uL).";
	p  "One entry in LBCO is not 10E3/UL but 10E3/L. This is probably a data entry error.";
	p  "Magnesium has LBORRESU5 equal to mg/dL or nmol/L, but sometimes there is no unit.";
	p  "Neutrophils has LBORREESU equal to 109/L or cells/uL, but sometimes there is no unit.";
	p  "Laboratory values are always judged NCS Abnormal or CS Abnormal, but never Normal.";
	p  "PC_DEVIATION is often equal to Yes even if there is no delay.";
	p  "PC_DELAY does not take into account the date. So time differences between two different days are wrong.";
	p  "PC_DEVIATION is sometimes equal to No even if sampling was done several hours earlier.";
	p  "PC_DEVIATION seems to suffer from a confusion between AM and PM in one case (as the deviation is 12 x 60 = 720 min).";
	p 	"U-Leucocytes always has the unit Leu/uL. However, its values are not always numerical but also +, NEG, N. Once, the value is in the free-text LCBO (NEGATIVE).";
run;

proc document name=tables;   replay; quit;
proc document name=figures;  replay; quit;
proc document name=listings; replay; quit;

ods pdf close;
