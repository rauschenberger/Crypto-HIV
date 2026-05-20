/******************************************************************************/
/*** current symptoms *********************************************************/
/******************************************************************************/

%put --- current symptoms ---;

%order_levels(code=CE,var=VISIT);
%label_vars(code=CE);

ods document name=tables(update);
proc tabulate data=CE;
	%title(type="table",label="Current Symptoms");
	title2 '(number of patients by visit and treatment)';
	class VISIT treatment CETERM / order=internal;
	table VISIT * CETERM * (n rowpctn='%'),
			treatment all='Total';
run;
ods document close;
