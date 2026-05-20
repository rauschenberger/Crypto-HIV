/******************************************************************************/
/*** demographics *************************************************************/
/******************************************************************************/

%put --- demographics ---;

%as_numeric(code=DM,var=vsorres_weight);
%as_numeric(code=DM,var=vsorres_height);
%as_numeric(code=DM,var=vsorres_bmi);
%as_numeric(code=DM,var=age);
%label_vars(code=DM);

ods document name=tables(update);
proc tabulate data=DM;
	%title(type="table",label='Demographics by Treatment');
	title2 "(top: summary statistics for numerical variables,";
	title3 "bottom: counts and percentages for categorical variables)";
	class treatment sex race;
	var age vsorres_weight vsorres_height vsorres_bmi;
	where not missing(treatment);
	table 	(age vsorres_weight vsorres_height vsorres_bmi)*(mean median std min max n)
			(sex race)*(n colpctn='%'),
			treatment all='Total';
run;
ods document close;

data DM_sub;
	retain USUBJID treatment age sex vsorres_weight vsorres_height vsorres_bmi race;
	set DM(keep=USUBJID treatment age sex vsorres_weight vsorres_height vsorres_bmi race);
	where not missing(treatment);
run;

ods document name=listings(update);
%report(data=DM_sub,title='Demographics',name=DM);
ods document close;
