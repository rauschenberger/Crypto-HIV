
/******************************************************************************/
/*** concomitant medications **************************************************/
/******************************************************************************/

%put --- concomitant medications ---;

%label_vars(code=CM);

data CM;
	set CM;
	Dosing = catx('',CMDOSE,CMDOSU_LIB) || ' (' || strip(CMDOSFRQ) || ', ' || strip(CMROUTE_LIB) || ')';
run;

ods document name=listings(update);
%macro cm_report;
proc report data=CM spanrows style(report)=[width=100%] style(column)=[cellwidth=12.4%] style(header)=[cellwidth=12.4%];
	%title(type="listing",label='Concomitant Medications');
	%if &standardise. = True %then %do;
		column USUBJID CMINDC CMTRT ATC_CLASSIFICATION_NAME Dosing CMSTDTC CMENDTC CMONGO;
	%end;
	%else %do;
		column USUBJID CMINDC CMTRT Dosing CMSTDTC CMENDTC CMONGO;
	%end;
	define USUBJID/order;
run;
%mend cm_report;
%cm_report;
ods document close;
