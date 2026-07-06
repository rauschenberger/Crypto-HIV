/******************************************************************************/
/*** medical history **********************************************************/
/******************************************************************************/

%put --- medical history ---;

%order_levels(code=MH,var=MHTERMPREP);
%label_vars(code=MH);

ods document name=tables(update);
proc tabulate data=MH;
	%title(type="table",label="Medical History");
	title2 '(number and percentage of patients by treatment)';
	class MHTERMPREP MHTERM_YN treatment /order=internal;
	table MHTERMPREP * MHTERM_YN='' * (n pctn<MHTERM_YN>='%'), treatment all='Total';
run;
ods document close;

ods document name=listings(update);
%macro mh_report;
proc report data=MH spanrows;
	%title(type="listing",label='Medical History By Patient');
	where not missing(RID) and not missing(MHTERMPREP) or not missing(MHTERM);
	%if &standardise. = True %then %do;
		column USUBJID MHTERMPREP MHTERM_YN MHTERM PT System_Organ_Class MHSTDAT MHENDAT MHONGO;
	%end;
	%else %do;
		column USUBJID MHTERMPREP MHTERM_YN MHTERM MHSTDAT MHENDAT MHONGO;
	%end;
	define USUBJID/order;
run;
%mend mh_report;
%mh_report;
ods document close;
