/******************************************************************************/
/*** ART initiation ***********************************************************/
/******************************************************************************/

%put --- ART initiation ---;

%label_vars(code=ART);

ods document name=listings(update);
proc report data=ART spanrows;
	%title(type="listing",label='ART Initiation');
	column USUBJID VISIT ARTINITDAT ARTREGIMEN ENHANCEDART;
	define USUBJID/order;
run;
ods document close;
