/******************************************************************************/
/*** lumbar punctures *********************************************************/
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
