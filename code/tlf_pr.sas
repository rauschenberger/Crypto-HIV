
/******************************************************************************/
/*** pregnancy ****************************************************************/
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
