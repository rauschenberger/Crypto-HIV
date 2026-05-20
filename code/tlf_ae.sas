/******************************************************************************/
/*** adverse events ***********************************************************/
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
