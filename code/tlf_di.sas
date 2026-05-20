/******************************************************************************/
/* * Subsection 4.X: discharge * * * * * * * * * * * * * * * * * * * * * * * */
/******************************************************************************/

%put --- discharge ---;

%label_vars(code=DI);

ods document name=listings(update);
proc report data=DI spanrows style(report)=[width=100%] style(column)=[cellwidth=9.0%] style(header)=[cellwidth=9.0%];
	%title(type="listing",label='discharge');
	column USUBJID VISIT LPPERF DISCHARGED DISCHAR_CONTRA FLOCO_MAINT PATIENT_ART REGIMEN_ART ART_ADHER TPT_ADMIN REGIMEN_TPT;
	define USUBJID/order;
run;
ods document close;
