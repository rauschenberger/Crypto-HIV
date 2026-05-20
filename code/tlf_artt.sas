
/******************************************************************************/
/** ART treatment *************************************************************/
/******************************************************************************/

%put --- ART treatment ---;

%label_vars(code=ARTT);

ods document name=listings(update);
proc report data=ARTT style(report)=[width=100%] style(column)=[cellwidth=8.33%] style(header)=[cellwidth=8.33%];
	%title(type="listing",label='ART Treatment');
	column USUBJID ARTSTDAT ART_FIRST_REGIMEN ART_SWITCH ARTSTDAT2 ART_CURRENT_REGIMEN ADHERENT_ART NB_MISSED_DOSES ART_DECISION VIRAL_LOAD_AVAILABLE VIRAL_LOAD_RESULT VIRALDAT;
	define USUBJID/order;
run;
ods document close;
