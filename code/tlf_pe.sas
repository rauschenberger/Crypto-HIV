/******************************************************************************/
/*** physical examination *****************************************************/
/******************************************************************************/

%put --- physical examination ---;

%label_vars(code=PE);

data PE_sub;
	retain USUBJID VISIT PETESTCD PEORRES PEORRES_SP;
	set PE(keep=USUBJID VISIT PETESTCD PEORRES PEORRES_SP);
	if PEORRES='D' then PEORRES='';
	where not missing(PEORRES) and PEORRES not in ('Normal','','D');
run;

ods document name=listings(update);
%report(data=PE_sub,title='Physical Examination with Abnormal Results',name=PE);
ods document close;
