/******************************************************************************/
/*** ineligibility ************************************************************/
/******************************************************************************/

%put --- ineligibility ---;

%label_vars(code=IE);

ods document name=tables(update);
proc tabulate data=IE;
	%title(type="table",label="Ineligibility");
	title2 "(number of patients satisfying an inclusion or exclusion criterion)";
	class IECAT IETEST IEORRES;
	table IECAT * IETEST, IEORRES * (n);
run;
ods document close;

ods document name=listings(update);
proc report data=IE spanrows;
	%title(type="listing",label='Ineligible Patients');
	where (IECAT='INCLUSION' and IEORRES='No') or (IECAT='EXCLUSION' and IEORRES='Yes');
	column USUBJID IECAT IETEST IEORRES EC_CHECK;
	define USUBJID/order;
	define IECAT/order;
run;
ods document close;
