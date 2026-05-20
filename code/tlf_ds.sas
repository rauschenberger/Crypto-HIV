/******************************************************************************/
/*** disposition milestones ***************************************************/
/******************************************************************************/

%put --- disposition milestones ---;

%order_levels(code=DS,var=DSDECOD);
%label_vars(code=DS);

/*
proc sort data=DS;
	by USUBJID;
run;

proc transpose data=DS out=DS_wide;
	by USUBJID;
	id DSSEQ;
	idlabel DSDECOD;
	var DSTERM;
run;

proc report data=DS_wide;
run;
*/

ods document name=tables(update);
proc tabulate data=DS;
	%title(type="table",label='Disposition Milestones');
	title2 '(number of patients)';
	class DSDECOD / order=internal;
	table DSDECOD='' * (n);
run;
ods document close;

/*
proc report data=DS spanrows;
	%title(type="listing",label='disposition milestones');
	*column USUBJID VISIT DSDECOD;
	define USUBJID/order;
run;
*/
