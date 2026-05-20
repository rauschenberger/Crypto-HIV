
/******************************************************************************/
/*** palatability acceptability **********************************************/
/******************************************************************************/
 
%put --- palatability ---;

%label_vars(code=QUEST);

/*
Find a more compact way of presenting this.
proc report data=QUEST;
	%title(type="listing",label='palatability acceptability');
run;
*/

/*
proc tabulate data=QUEST;
	class VISIT treatment PARTICIPANT_Q1 PARTICIPANT_Q2;
	table VISIT * (PARTICIPANT_Q1 PARTICIPANT_Q2), treatment all='Total';
run;
*/
	
/* CONTINUE HERE: tabulate with different levels for each variable? */ 
