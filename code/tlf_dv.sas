
/******************************************************************************/
/*** protocol deviations ******************************************************/
/******************************************************************************/

%put --- protocol deviations ---;

%label_vars(code=DV);

ods document name=tables(update);
proc tabulate data=DV;
	%title(type="table",label="Protocol Deviations");
	title2 "(number and percentage by treatment)";
	class treatment DVCAT;
	table DVCAT * (n rowpctn='%'),
		treatment all="total";
run;
ods document close;

data DV_sub;
	retain USUBJID VISIT FORM DVTERM DVCAT;
	set DV(keep=USUBJID VISIT FORM DVTERM DVCAT);
run;

ods document name=listings(update);
%report(data=DV_sub,title='Protocol Deviations',title2='(sorted by patient and visit)',name=DV);
ods document close;
