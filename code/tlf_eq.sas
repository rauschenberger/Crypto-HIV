
/******************************************************************************/
/*** quality of life **********************************************************/
/******************************************************************************/

%put --- quality of life ---;

%label_vars(code=EQ);

ods document name=listings(update);
proc report data=EQ;
	%title(type="listing",label="Quality of Life (EQ-5D-3L)");
	column USUBJID VISIT treatment MOBILITY SELFCARE USUALACTIVITIES PAINDISCOMFORT ANXIETYDEPRESSION SCALE;
	where not missing(MOBILITY) or not missing(SELFCARE) or not missing(USUALACTIVITIES) or not missing(PAINDISCOMFORT) or not missing(ANXIETYDEPRESSION) or not missing (SCALE);
run;
ods document close;
