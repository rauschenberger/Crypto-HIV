/******************************************************************************/
/*** Section 3: Formats *******************************************************/
/******************************************************************************/

proc format;
	invalue PAGENAME_invalue
		'ECG' = 0
 		'ECG - 2 hours post-dose - only for Ancotil' = 2
 		'ECG - 4 hours post-dose - only for Flucitosine' = 4
 		'ECG - 8 hours (2 hours after 2nd dose Ancotil)' = 8
		'ECG - 48 hours post-dose' = 48
		;
	value PAGENAME_value
		0 = 'ECG'
 		2 = 'ECG - 2 hours post-dose - only for Ancotil'
 		4 = 'ECG - 4 hours post-dose - only for Flucitosine'
 		8 = 'ECG - 8 hours (2 hours after 2nd dose Ancotil)'
		48 = 'ECG - 48 hours post-dose'
		;
	invalue time_invalue
		'screen' = 0
		'P1: pre-dose' = 1
		'P1: 2h' = 2 
		'P1: 4h' = 3
		'P1: 6h' = 4
		'P1: 48h' = 5
		'P2: pre-dose' = 6
		'P2: 2h' = 7 
		'P2: 4h' = 8
		'P2: 6h' = 9
		'P2: 48h' = 10
		'post-study' = 11 
		'unscheduled' = .
		;
	value time_value
		0 = 'screen'
		1 = 'P1: pre-dose'
		2 = 'P1: 2h'
		3 = 'P1: 4h'
		4 = 'P1: 6h'
		5 = 'P1: 48h'
		6 = 'P2: pre-dose'
		7 = 'P2: 2h'
		8 = 'P2: 4h'
		9 = 'P2: 6h'
		10 = 'P2: 48h'
		11 = 'post-study' 
		other = .
		;
	invalue FORM_invalue
		'Pre-dose' = 1
		'2 hours post-dose' = 2
		'4 hours post-dose' = 3
		'6 hours post-dose' = 4
		'48 hours post-dose' = 5
		; 
	value FORM_value
		1 = 'Pre-dose'
		2 = '2 hours post-dose'
		3 = '4 hours post-dose'
		4 = '6 hours post-dose'
		5 = '48 hours post-dose'
		;
	invalue PC_SAMPLING_TIME_invalue
		'Pre-dose' = 0
		'2' = 2
		'4' = 4
		'6' = 6
		'7.5' = 7.5
		'12' = 12
		'24' = 24
		;
	value PC_SAMPLING_TIME_value
		 0 = 'Pre-dose'
		 2 = '2'
		 4 = '4'
		 6 = '6'
		 7.5 = '7.5'
		 12 = '12'
		 24 = '24'
		;
	/*
	invalue VSTEST_invalue
		'Weight' = 1
 		'Height' = 2
 		'Body Mass Index' = 3
 		'Body Temperature' = 4
		'Systolic Blood Pressure' = 5
		'Diastolic Blood Pressure' = 6
		'Pulse Rate' = 7
		'Oxygen Saturation' = 8
		'Respiratory Rate' = 9
		;
	value VSTEST_value
		1 = 'Weight'
 		2 = 'Height'
 		3 = 'Body Mass Index'
 		4 = 'Body Temperature'
		5 = 'Systolic Blood Pressure'
		6 = 'Diastolic Blood Pressure'
		7 = 'Pulse Rate'
		8 = 'Oxygen Saturation'
		9 = 'Respiratory Rate'
		;
	invalue EGTEST_invalue
		'Heart Rate' = 1
		'P Wave Axis' = 2
		'P Wave Duration, Aggregate' = 3
		'PR Interval, Aggregate' = 4
		'QRS Duration, Aggregate' = 5
		'QT Interval, Aggregate' = 6
		'QTc, Fredericia' = 7
		'RR Interval, Aggregate ' = 8
	;
	value EGTEST_value
		1 = 'Heart Rate'
		2 = 'P Wave Axis' 
		3 = 'P Wave Duration, Aggregate' 
		4 = 'PR Interval, Aggregate' 
		5 = 'QRS Duration, Aggregate' 
		6 = 'QT Interval, Aggregate'
		7 = 'QTc, Fredericia'
		8 = 'RR Interval, Aggregate '
	;
	*/
	invalue VSSTRESC_invalue
		'N/A' = 0
		'Normal' = 1
		'NCS' = 2
		'CS' = 3
		;
	value VSSTRESC_value
		0 = 'N/A'
	 	1 = 'Normal'
		2 = 'Abnormal, NCS'
		3 = 'Abnormal, CS'
		;
	invalue SUOCCUR_invalue
		'No' = 0
		'Yes' = 1
		;
	value SUOCCUR_value
		0 = 'No'
		1 = 'Yes'
		;
	invalue SUTRT_invalue
		'ALCOHOL' = 1
		'SMOKER' = 2
		'OTHER' = 3
		;
	value SUTRT_value
		1 = 'ALCOHOL'
		2 = 'SMOKER'
		3 = 'OTHER'
		;
	invalue EGSTRESC1_invalue
		'Normal' = 0
		'Abnormal, NCS' = 1
		'Abnormal, CS' = 2
		;
	value EGSTRESC1_value
		0 = 'Normal'
		1 = 'Abnormal, NCS'
		2 = 'Abnormal, CS'
		;
	invalue LBCLSIG_invalue
		'Normal' = 0
		'NCS' = 1
		'CS' = 2
		;
	value LBCLSIG_value
		0 = 'Normal'
		1 = 'Abnormal, NCS'
		2 = 'Abnormal, CS'
		;
	invalue VISIT_invalue
 		'Screening' = 0
		'Screening Visit' = 0
		'Day 1' = 1
		'DAY 1' = 1
		'Treatment Day 1' = 1
 		'Day 2' = 2
		'Treatment Day 2' = 2
		'Day 3' = 3
		'Treatment Day 3' = 3
		'Day 4' = 4
		'Treatment Day 4' = 4
		'Day 5' = 5
		'Treatment Day 5' = 5
		'Day 6' = 6
		'Treatment Day 6' = 6
		'Day 7' = 7
		'Day 7 Visit' = 7
		'Treatment Day 7' = 7
		'Treatment Day 8' = 8
		'Treatment Day 9' = 9
		'Treatment Day 10' = 10
		'Treatment Day 11' = 11
		'Treatment Day 12' = 12
		'Treatment Day 13' = 13
		'Treatment Day 14' = 14
		'Day 15' = 15
		'Treatment Day 15' = 15
		'Sparse PK - Day 15' = 15
		'Day 21 Visit' = 21
		'Week 4' = 28
		'Week 6' = 42
		'Week 6 Visit' = 42
		'Week 10' = 70
		'Week 10/Early Withdrawal Visit' = 70
		'Unscheduled' = 99
		'Unscheduled Visit' = 99
		'End of Study' = 100
		'Death' = 101
		;
	value VISIT_value
 		0 = 'Screening'
		1 = 'Day 1'
 		2 = 'Day 2'
		3 = 'Day 3'
		4 = 'Day 4'
		5 = 'Day 5'
		6 = 'Day 6'
		7 = 'Day 7'
		8 = 'Day 8'
		9 = 'Day 9'
		10 = 'Day 10'
		11 = 'Day 11'
		12 = 'Day 12'
		13 = 'Day 13'
		14 = 'Day 14'
		15 = 'Day 15'
		21 = 'Day 21'
		28 = 'Week 4'
		42 = 'Week 6'
		70 = 'Week 10'
		99 = 'Unscheduled'
		100 = 'End of Study'
		101 = 'Death'
		;
	invalue DSDECOD_invalue
		'INFORMED CONSENT OBTAINED' = 1
		'NOT RANDOMIZED' = 2
		'RANDOMIZED' = 3
		'ENROLLED' = 4
		'COMPLETED' = 5
		;
	value DSDECOD_value
		1 = 'informed consent obtained'
		2 = 'not randomized'
		3 = 'randomized'
		4 = 'enrolled'
		5 = 'completed'
		;
	invalue CMROUTE_invalue
		"Oral Route of Administration" = 1
		"Intravenous Route of Administration" = 2
		;
	value CMROUTE_value
		1 = "oral"
		2 = "intravenous"
		;
	invalue MHTERMPREP_invalue
		'Previous medical history of TB' = 1     
		'Previous opportunistic infections other than TB' = 2      
		'Previous HIV diagnosis' = 3 
		'Previous anti-viral treatment' = 4
		'Additional serious, life-threatening disease according to site PI' = 5
		;
	value MHTERMPREP_value
		1 = 'Previous medical history of TB'    
		2 = 'Previous opportunistic infections other than TB'      
		3 = 'Previous HIV diagnosis'
		4 = 'Previous anti-viral treatment'
		5 = 'Additional serious, life-threatening disease according to site PI'
		;
	invalue AESEV_invalue
		'Mild' = 1
		'Moderate' = 2
		'Severe' = 3
		'Life threatening' = 4
		;
	value AESEV_value
		1 = 'Mild'
		2 = 'Moderate'
		3 = 'Severe'
		4 = 'Life threatening'
		;
	invalue EXDOSNB_invalue
		'' = 0
		'FIRST DOSE' = 1
		'SECOND DOSE' = 2
		'THIRD DOSE' = 3
		'FOURTH DOSE' = 4
		;
	value EXDOSNB_value
		0 = ' '
		1 = 'FIRST DOSE'
		2 = 'SECOND DOSE'
		3 = 'THIRD DOSE'
		4 = 'FOURTH DOSE'
		;
run;

proc format; 
	%let low='LIGR'; /*pale blue: '#4ED3D4'*/
	%let high='LIGR'; /*pale red: '#D9544D'*/
	/* vital signs*/
	value 	BODTEM 		low-35.5=&low. 
						35.5-37.5='white' 
						37.5-high=&high.;
	value SBP			low-90=&low.
						90-140='white'
						140-high=&high.;
	value DBP			low-60=&low.
						60-90='white'
						90-high=&high.;
	/*
	value	sup_sys 	low-90=&low.
						90-140='white'
						140-high=&high.;
	value	sup_dia 	low-45=&low.
						45-90='white'
						90-high=&high.;
	value	sta_sys 	low-85=&low.
						85-150='white'
						150-high=&high.;
	value	sta_dia 	low-50=&low.
						50-95='white'
						95-high=&high.;
	*/
	value	PULSE 		low-40=&low.
						40-100='white'
						100-high=&high.;
	value 	RESPIR		low-12=&low.
						12-20='white'
						20-high=&high.;
	value	OXYSAT		low-95=&low.
						95-100='white'
						100-high=&high.;
	/* ECG */ 
	value ECG_HR		low-40=&low.
						40-100='white'
						100-high=&high.;
	value ECG_RR		low-600=&low.
						600-1000='white'
						1000-high=&high.;
	value ECG_QRS		low-0=&low.
						0-119='white'
						119-high=&high.;
	value ECG_QTint		low-350=&low.
						350-440='white'
						440-high=&high.;
	value ECG_QTc		low-0=&low.
						0-460='white'
						460-high=&high.;
	value ECG_PR		low-120=&low.
						120-220='white'
						220-high=&high.;
	value ECG_axis		low--30=&low.
						-30-90='white'
						90-high=&high.;
	value ECG_wave 		low-0=&low.  
						0-130='white' /*unknown normal range*/
						130-high=&high.;
	/* GCS */
	value GCS_total		15 = 'white'
						other = &low.;
	value $GCS_eye		'Eye open spontaneously' = 'white'
						other = &low.;
	value $GCS_verbal	'Orientated' = 'white'
						other = &low.;
	value $GCS_motor	'Obeys commands' = 'white'
						other = &low.;
	/* PE */
	value $PEORRES		
						'Normal' = 'white'
						'Abnormal, NCS' = 'white'
						'' = 'white'
						'.' = 'white'
						'Abnormal, CS' = &high.
						other = &high.;
	/* DV */
	value $DVCAT		'Minor' = 'white'
						'Major' = &high.
						other = &high.; 
	/* PR */ 
	value $PREGPERF		'Yes'='white'
						other = &low.;
	value $PREGORRES	'Negative' = 'white'
						other = &high.;
	/* AE */
	value $AESEV		'Mild' = 'white'
						'Moderate' = 'white'
						other = &high.;
	value $AEOUT		'Recovered/Resolved' = 'white'
						'Recovering/Resolving' = 'white'
						'Unknown' = &high.
						'Not Recovered/Not Resolved' = &high.
						other = &high.;
	value $AEREL_one	'Not related with Arm 1' = 'white'
						'Not Related with Arm 1' = 'white'
						'Probably not Related with Arm 1' = 'white'
						'.' = 'white'
						'' = 'white'
						' ' = 'white'
						'Possibly Related with Arm 1' = &high.
						'Probably Related with Arm 1' = &high.
						'Definitely Related with Arm 1' = &high.
						other = &high.;
	value $AEREL_two	'Not related with Arm 2' = 'white'
						'Not Related with Arm 2' = 'white'
						'Probably not Related with Arm 2' = 'white'
						'.' = 'white'
						'' = 'white'
						' ' = 'white'
						'Possibly Related with Arm 2' = &high.
						'Probably Related with Arm 2' = &high.
						'Definitely Related with Arm 2' = &high.
						other = &high.;	
	value $PC_DEVIATION 'No' = 'white'
						'Yes' = &high.
						other = &high.;
	VALUE PC_DELAY		low--20 = &low.
						-20-20 = 'white'
						20-high = &high.;	
run; 

/* colour extreme values */ 
%macro color(name=);
	%if &name.=VS %then %do;
	compute 'Body Temperature (°C)'n;
		call define(_col_,'style','style={background=BODTEM.}');
	endcomp;
	compute 'Systolic Blood Pressure (mmHg)'n;
		call define(_col_,'style','style={background=SBP.}');
		/*
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_sys.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_sys.}');
		end;
		*/
	endcomp;
	compute 'Diastolic Blood Pressure (mmHg)'n;
		call define(_col_,'style','style={background=DBP.}');
		/*
		if VSPOS = 'Supine' then do;
			call define(_col_,'style','style={background=sup_dia.}');
		end;
		else if VSPOS='Standing' then do;
			call define(_col_,'style','style={background=sta_dia.}');
		end;
		*/
	endcomp;
	compute 'Pulse Rate (beats/min)'n;  /* per */
			call define(_col_,'style','style={background=PULSE.}');
	endcomp;
	compute 'Respiratory Rate (beats/min)'n;  /* per */
			call define(_col_,'style','style={background=RESPIR.}');
	endcomp;
	compute 'Oxygen Saturation (%)'n;
			call define(_col_,'style','style={background=OXYSAT.}');
	endcomp;
	%end;
	%if &name.=EG %then %do;
	compute 'Heart Rate (bpm)'n;
		call define(_col_,'style','style={background=ECG_HR.}');
	endcomp;
	compute 'RR Interval, Aggregate'n;
		call define(_col_,'style','style={background=ECG_RR.}');
	endcomp;
	compute 'QRS Duration, Aggregate (msec)'n;
		call define(_col_,'style','style={background=ECG_QRS.}');
	endcomp;
	compute 'QT Interval, Aggregate (msec)'n;
		call define(_col_,'style','style={background=ECG_QTint.}');
	endcomp;
	compute 'QTc, Fredericia (msec)'n;
		call define(_col_,'style','style={background=ECG_QTc.}');
	endcomp;
	compute 'PR Interval, Aggregate (msec)'n;
		call define(_col_,'style','style={background=ECG_PR.}');
	endcomp;
	compute 'P Wave Duration, Aggregate (msec'n;
		call define(_col_,'style','style={background=ECG_wave.}');
	endcomp;
	compute 'P Wave Axis (degrees)'n;
		call define(_col_,'style','style={background=ECG_axis.}');
	endcomp;
	%end;
	%if &name.=GC %then %do;
	compute GCS_TOTAL;
		call define(_col_,'style','style={background=GCS_total.}');
	endcomp;
	compute BESTEYERESPONSE;
		call define(_col_,'style','style={background=$GCS_eye.}');
	endcomp;
	compute BESTVERBALRESPONSE;
		call define(_col_,'style','style={background=$GCS_verbal.}');
	endcomp;
	compute BESTMOTORRESPONSE;
		call define(_col_,'style','style={background=$GCS_motor.}');
	endcomp;
	%end;
	%if &name.=PE %then %do;
	compute PEORRES / character length=50;
		call define(_col_,'style','style={background=$PEORRES.}');
	endcomp;
	%end;
	%if &name.=DV %then %do;
	compute DVCAT / character length=50;
		call define(_col_,'style','style={background=$DVCAT.}');
	endcomp;
	%end;
	%if &name.=PR %then %do;
	compute PREGPERF / character length=50;
		call define(_col_,'style','style={background=$PREGPERF.}');
	endcomp;
	compute PREGORRES / character length=50;
		call define(_col_,'style','style={background=$PREGORRES.}');
	endcomp;
	%end;
	%if &name.=AE %then %do;
	compute AESEV_ / character length=50;
		call define(_col_,'style','style={background=$AESEV.}');
	endcomp;
	compute AEOUT / character length=50;
		call define(_col_,'style','style={background=$AEOUT.}');
	endcomp;
	compute AEREL / character length=50;
		call define(_col_,'style','style={background=$AEREL_one.}');
	endcomp;
	compute AEREL1 / character length=50;
		call define(_col_,'style','style={background=$AEREL_two.}');
	endcomp;
	%end;
	%if &name.=PC %then %do;
	compute PC_DEVIATION / character length=50;
		call define(_col_,'style','style={background=$PC_DEVIATION.}');
	endcomp;
	compute PC_DELAY;  /* per */
		call define(_col_,'style','style={background=PC_DELAY.}');
	endcomp;
	%end;
%mend color;
/*
Arguments: Choose one of two CDISC abbreviations (either 'VS' or 'EG').
Description: This macro uses colour for values below or above the normal range.
*/

%macro title(type=, label=);
	%let type = %sysfunc(dequote(&type.));
    %if not %symexist(&type._n) %then %do;
		%global &type._n;
        %let &type._n = 0;
    %end;
    %let &type._n = %eval(&&&type._n + 1);
    %let labtitle = %upcase(&type) &&&type._n: %sysfunc(dequote(&label.));
	/*ods pdf startpage=now;*/
    title "&labtitle";
    ods proclabel "&labtitle";
%mend title;
