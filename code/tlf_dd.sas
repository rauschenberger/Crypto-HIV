
/******************************************************************************/
/*** death details ************************************************************/
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
