
/******************************************************************************/
/*** vital signs **************************************************************/
/******************************************************************************/

%put --- vital signs ---;

data VS;
	set VS;
	if VSPOS in (' ','.') then VSPOS='N/A';
	if VSSTRESC in (' ','.') then VSSTRESC='N/A';
	where VSTEST not in ('Weight','Height','Body Mass Index');
run;

%order_levels(code=VS,var=VISIT);
/*%order_levels(code=VS,var=VSTEST);*/
%order_levels(code=VS,var=VSSTRESC);
/*%order_levels(code=VS,var=time);*/
%as_numeric(code=VS,var=VSORRES);
/*%sub_per(code=VS);*/
%add_unit(code=VS);
%label_vars(code=VS);

/* table: vital signs at screening visit by treatment */ 
ods document name=tables(update);
%tabulate(code=VS,visit="Screening");
ods document close;

/* try report with colour

proc report data=VS;
	where RID=102 and VISIT_='Screening';
    columns RID VISIT VSTEST VSSTRESC_ VSORRES;
    define VSORRES  / display;
    define VSSTRESC_ / display;
    compute VSORRES;
        if VSSTRESC_ = 'Abnormal, NCS' then
            call define(_col_, 'style', 'style=[backgroundcolor=grey color=white]');
		if VSSTRESC_ = 'Abnormal, CS' then
            call define(_col_, 'style', 'style=[backgroundcolor=black color=white]');
    endcomp;
run;


%getvars(code=VS);
%extract_ids_abnormal(code=VS,visit='Screening');
data long;
	set VS;
	if RID=102;
	if VISIT_='Screening';
run; 
proc sort data=long;
	by RID VISIT_;
run;
options validvarname=any;
proc transpose data=long out=wide;
	by RID VISIT_;
	id VSTEST;
	var VSORRES VSSTRESC_;
run;
proc report data=wide;
run;
options validvarname=v7;

end trial */ 

/* listing: abnormal at screening */
ods document name=listings(update);
%list_abnormal(code=VS,check_visit='Screening',show_visit='Screening' 'Unscheduled',width=8%);
ods document close;

/* tables: values of and change in vital signs*/
ods document name=tables(update);
%process_table(code=VS,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg)|Pulse Rate (beats/min)|Respiratory Rate (beats/min)|Oxygen Saturation (%)); /* per */
ods document close;

/*table: count of abnormal values */

proc summary data=VS nway;
	where not missing(RID);
	class VSSTRESC VSTEST RID VISIT treatment;
	output out=temp;
run;

ods document name=tables(update);
proc tabulate data=temp;
	%title(type="table",label='Count and Percentage of Normal, NCS or CS Abnormal Vital Signs');
	title2 '(by visit, vital sign, and treatment)';
	where not missing(RID);
	class VISIT treatment VSTEST VSSTRESC RID / order=internal;
	table VISIT * VSTEST * VSSTRESC * (n pctn<VSSTRESC>='%'),
		  treatment;
run;
ods document close;

/* listing: abnormal during treatment */
ods document name=listings(update);
%list_abnormal(code=VS,check_visit=&treat_days.,show_visit=&treat_days. &post_weeks.);
ods document close;

/* figures: trajectories of patients with abnormal values */
ods document name=figures(update);
%process_traject(code=VS,check_visit=&treat_days.,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg))
ods document close;

/* figures: mean values and mean change */
ods document name=figures(update);
%process_trend(code=VS,tests=Systolic Blood Pressure (mmHg)|Diastolic Blood Pressure (mmHg)|Pulse Rate (beats/min)) /* per */
ods document close;

/* vital signs post study, by treatment */
ods document name=tables(update);
%tabulate(code=VS,visit="Week 10");
ods document close;
