
/******************************************************************************/
/*** pharmacokinetics *********************************************************/
/******************************************************************************/

%put --- pharmacokinetics ---;

%order_levels(code=PC,var=PC_SAMPLING_TIME);
%as_numeric(code=PC,var=PC_DELAY);
%label_vars(code=PC);

ods document name=tables(update);
proc tabulate data=PC;
	%title(type="table",label="Calculated Delay in Blood Sampling for Pharmacokinetics");
	title2 '(in minutes, by visit and treatment)';
	class VISIT PC_SAMPLING_TIME treatment /order=internal;
	var PC_DELAY;
	table VISIT * PC_SAMPLING_TIME * PC_DELAY='' * (mean median std min max n), treatment all="total";
run;
ods document close;

data PC;
	set PC;
	if VISIT in ('Day 1','Day 2') then do;
		idv = cats(RID,'_one');
	end;
	else if VISIT in ('Day 6','Day 7') then do;
		idv = cats(RID,'_two');
	end;
run;

data temp;
	set PC;
	where not missing(PC_DELAY) and (PC_DELAY < -20 or PC_DELAY > 20);
run;

proc sql noprint;
	select distinct quote(trim(idv),"'")
	into :idv_delay separated by ','
	from temp;
quit;

ods document name=listings(update);
proc report data=PC spanrows;
	%color(name=PC);
	%title(type="listing",label="Patients with a PK Blood Sampling Deviation");
	title2 '(patients on days 1/2 or 6/7 with <-20 or >20 minutes)'; 
	columns USUBJID VISIT PC_SAMPLING_TIME PCTPTREF PCDTC PC_DEVIATION PC_DELAY PC_DELAY_RSN ;
	where idv in (&idv_delay.);
	define USUBJID/order;
	define VISIT/order;
run;
ods document close;
