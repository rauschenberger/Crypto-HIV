
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
proc report data=CM spanrows style(report)=[width=100%] style(column)=[cellwidth=12.4%] style(header)=[cellwidth=12.4%];
	%title(type="listing",label='Concomitant Medications');
	column USUBJID CMINDC CMTRT ATC_CLASSIFICATION_NAME Dosing CMSTDTC CMENDTC CMONGO;
	define USUBJID/order;
run;
ods document close;
