
/******************************************************************************/
/*** Rankin disability questionnaire ******************************************/
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
