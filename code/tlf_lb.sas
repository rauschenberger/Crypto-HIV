
/******************************************************************************/
/*** laboratory ***************************************************************/
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
