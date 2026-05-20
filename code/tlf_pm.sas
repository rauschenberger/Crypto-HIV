
/******************************************************************************/
/*** prior medications ********************************************************/
/******************************************************************************/

%put --- prior medications ---;

%label_vars(code=PM);

data PM;
	set PM;
	length CMDOSU_LIB $60;
	if CMDOSU='Milligram' then do;
		CMDOSU_LIB = 'mg';
	end;
	else if CMDOSU = 'Gram' then do;
		CMDOSU_LIB = 'g';
	end;
	else if CMDOSU = 'International Unit' then do;
		CMDOSU_LIB = 'IU';
	end;
	else do;
		CMDOSU_LIB = CMDOSU;
	end;
	length CMROUTE_LIB $60;
	if CMROUTE = 'Oral Route of Administration' then do;
		CMROUTE_LIB = 'oral';
	end;
	else if CMROUTE = 'Intravenous Route of Administration' then do;
		CMROUTE_LIB = 'intravenous';
	end;
	else do;
		CMROUTE_LIB = CMROUTE;
	end;
	Dosing = catx('',CMDOSE,CMDOSU_LIB) || ' (' || strip(CMDOSFRQ) || ', ' || strip(CMROUTE_LIB) || ')';
run;

ods document name=listings(update);
proc report data=PM spanrows;
	%title(type="listing",label='Prior Medications');
	column USUBJID CMTRT ATC_CLASSIFICATION_NAME Dosing CMINDCREF;
	define USUBJID/order;
run;
ods document close;
