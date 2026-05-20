
/******************************************************************************/
/*** Glasgow coma score *******************************************************/
/******************************************************************************/

%put --- coma score ---;

%order_levels(code=GC,var=VISIT);
%as_numeric(code=GC,var=GCS_TOTAL);
%label_vars(code=GC);

data GC;
	set GC;
	length GCS_max $5;
	if GCSPERF='Yes' then do;
		if GCS_TOTAL=15 then GCS='=15';
		else GCS='<15';  
	end;
	else do;
		GCS='N/A';
	end;
run;

ods document name=tables(update);
proc tabulate data=GC;
	%title(type="table",label="Glasgow Coma Scale - Fully Awake Patients");
	title2 '(by visit and treatment)';
	class VISIT GCS treatment / order=internal;
	table VISIT * GCS * (n pctn<GCS>='%'),
			treatment all='Total';
run;
ods document close;

data GC_sub;
  	retain USUBJID VISIT GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE GCS_TOTAL;
	set GC(keep=USUBJID VISIT GCSPERF BESTEYERESPONSE BESTVERBALRESPONSE BESTMOTORRESPONSE GCS_TOTAL);
	where GCSPERF="Yes"; /*and GCS_TOTAL < 15*/
	drop GCSPERF;
run;

ods document name=listings(update);
%report(data=GC_sub,title='Glasgow Coma Scale',name=GC);
ods document close;
