/******************************************************************************/
/*** current symptoms *********************************************************/
/******************************************************************************/

%put --- current symptoms ---;

%order_levels(code=CE,var=VISIT);
%label_vars(code=CE);

ods document name=tables(update);
%macro ce_tabulate;
proc tabulate data=CE;
	%title(type="table",label="Current Symptoms");
	title2 '(number of patients by visit and treatment)';
	%if &standardise. = True %then %do;
		class VISIT treatment CETERM Primary_System_Organ_Class Preferred_term / order=internal;
		table VISIT * Primary_System_Organ_Class * Preferred_term * (n rowpctn='%'),
			treatment all='Total';
	%end;
	%else %do;
		class VISIT treatment CETERM / order=internal;
		table VISIT * CETERM * (n rowpctn='%'),
			treatment all='Total';
	%end;
run;
%mend ce_tabulate;
%ce_tabulate;
ods document close;
