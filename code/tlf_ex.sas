
/******************************************************************************/
/*** treatment exposure *******************************************************/
/******************************************************************************/

%put --- treatment exposure ---;

%order_levels(code=EX,var=VISIT);
%order_levels(code=EX,var=EXDOSNB);
%label_vars(code=EX);

data EX;
	set EX;
	dose = EXTRT || EXDOSNB;
run;

ods document name=tables(update);
proc tabulate data=EX missing;
	%title(type="table",label="Treatment Exposure");
	title2 '(by visit and treatment)';
	class VISIT dose treatment EXDOSNB EXTRT /order=internal;
	table VISIT * (EXDOSNB * EXTRT) * (n), treatment;
run;
ods document close;

/* VERIFY HERE WHETHER TREATMENT MATCHES WITH RELATED WITH ARM 1 / ARM 2 IN VARIABLE EXARM!*/ 

%put WARNING: This script is using a dummy randomisation list!;

data EX_sub;
	retain USUBJID VISIT EXDOSNB EXTRT EXSTDAT EXSTTIM EXROUTE;
	set EX(keep=USUBJID VISIT EXDOSNB EXTRT EXSTDAT EXSTTIM EXROUTE);
run;

ods document name=listings(update);
%report(data=EX_sub,title='Treatment Exposure',name=EX);
ods document close;
