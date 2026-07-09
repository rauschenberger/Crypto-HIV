
/******************************************************************************/
/*** Crypto-HIV phase II study  ***********************************************/
/*** Armin Rauschenberger *****************************************************/
/******************************************************************************/

/*
Remaining issues

Franck (2026-05-18):
- Tables with Yes/No should only show the counts for 'YES' and indicate in a footnote that there a no missing values.
- Similarly, tables with Normal/Abnormal should only show the counts for 'Abnormal' and include a footnote.
- Tables with separate blocks for numerical and categorical variables should be split into two tables.
- Medical history: Reported term and other term should be combined into one column.
- Adverse events: Relation to arm 1 and to arm 2 should be combined into one column.
- Concomitant medication: Ongoing='Yes' could be moved to the enddate column (i.e., enddate = 'ongoing').
- Physical examination: Define abbreviations in a footnote (e.g., HEENT).
- Clinical chemistry (and others): Show unscheduled visit only if there is at least one non-missing value.

Michel (2026-05-20):
- Symptoms: medical coding and table per system organ class and preferred term? => added SOC and PT
- Adverse events: idem => added SOC and PT
  and maybe one table of “at least one AE per patient” but let’s see if they request it => NOT YET DONE
- Vital signs: body temp has only the “N” line => The other lines are on the previous page.
- Urinalysis: Variable name appear in the column “Result” sometimes i.e. “Laboratory Test”,  => I can't find any occurence in the current version.
- Figures: the unit is missing in the X-axis title => Added units to both axes.

Armin:
- The entry "D" means "not done" and the entry "A" means "not applicable". Replace both by NA!
- Data set PE variable PEORRES should have the possible values "Normal", Abnormal, NCS" and "Abnormal, CS" but also has the value "D".
- PC: Combine two columns on reasons! The second one is currently empty but might contain data in the future.
- continue discussion on data corrections
- do not overwrite variables when bringing values to the same unit
- check NCS and CS in LB_LABORATORY
- The dataset on drug accountability is empty. It does not contain any information on taken and remaining amounts.
- QUEST: include this in report?
- Trigger an error if randomised and actual treatment differs.
- The warning "Argument 2 to function SUBSTR referenced by the %SYSFUNC or %QSYSFUNC macro function is out of range" should disappear once Leucocytes has units.
- Treatment exposure: Several times, a treatment dose is not indicated as administrated (i.e., EXTRTYN is empty), but there is a date and a time for the dose.
*/

/*
This SAS script requires three manual interventions:
(1) Specify the paths to your input and output directories in Section 1.
(2) a) First run the SAS script before the WinNonlin part.
	b) Then calculate the PK parameters in WinNonlin (see below '%put Note:')
	c) Finally run the SAS script after the WinNonlin part.
*/

x "cd C:\Users\arauschenberger\Desktop\Crypto-HIV\repository";

%let standardise = True; /* Set to False to use verbatim terms.*/ 

%include "code/setup.sas";
%include "code/macros.sas";
%include "code/format.sas";
%include "code/import.sas";

%global table_n figure_n listing_n;
%let table_n   = 0; %let figure_n  = 0; %let listing_n = 0; title;
ods document name=tables(write); ods document close;
ods document name=figures(write); ods document close;
ods document name=listings(write); ods document close;

%include "code/tlf_dm.sas"; /* demographics */
%include "code/tlf_mh.sas"; /* medical history */
%include "code/tlf_pm.sas"; /* prior medications */
%include "code/tlf_ie.sas"; /* ineligibility */
%include "code/tlf_dv.sas"; /* protocol deviations */
%include "code/tlf_ds.sas"; /* disposition milestones */
%include "code/tlf_di.sas"; /* discharge */
%include "code/tlf_art.sas"; /* ART initiation */
%include "code/tlf_artt.sas"; /* ART treatment */
%include "code/tlf_ex.sas"; /* treatment exposure */
%include "code/tlf_da.sas"; /* drug accountability */
%include "code/tlf_cm.sas"; /* concomitant medications */
%include "code/tlf_ce.sas"; /* current symptoms */
%include "code/tlf_ae.sas"; /* adverse events */
%include "code/tlf_pe.sas"; /* physical examination */
%include "code/tlf_vs.sas"; /* vital signs */
%include "code/tlf_gc.sas"; /* Glasgow coma score */
%include "code/tlf_lp.sas"; /* lumbar punctures */
%include "code/tlf_lb.sas"; /* laboratory */
%include "code/tlf_eg.sas"; /* electrocardiogram */
%include "code/tlf_rankin.sas"; /* Rankin disability questionnaire */
%include "code/tlf_dd.sas"; /* death details */
%include "code/tlf_pr.sas"; /* pregnancy */
%include "code/tlf_eq.sas"; /* quality of life */
%include "code/tlf_quest.sas"; /* palatability acceptability */
%include "code/tlf_pc.sas"; /* pharmacokinetics */

title ' ';
options nodate nonumber;
ods escapechar='^';
%let date = %sysfunc(today(), yymmdd10.);
%let filename = Crypto-HIV_&date.;
ods pdf file="&pathOut.\\&filename..pdf" style=printer startpage=yes;
ods pdf text="^S={just=c font_size=24pt font_weight=bold} ^10n 5FC HIV-Crypto";
ods pdf text="^S={just=c font_size=24pt} ^1n Tables, Figures, and Listings";
ods pdf text="^S={just=c font_size=14pt} ^10n Armin Rauschenberger";
ods pdf text="^S={just=c font_size=14pt} ^1n %sysfunc(today(), worddate.)";
ods pdf text="^S={just=c font_size=14pt} ^5n ";

proc odstext;
	h1 "Disclaimer";
	p  "^{style [color=red fontweight=bold] Problems in the datasets (see below) have not yet been fixed.}";
	p  "^{style [color=red fontweight=bold] Reference ranges (VS, EG, and LB) and conversion factors (LB) have not yet been provided.}";
	p  "^{style [color=red fontweight=bold] The SAS code has not yet been double-checked.}";
run;

ods text="Please add text directly to the source code (.sas) and not to the compiled document (.pdf or .docx). Otherwise each update in the data or the code will erase the text.";

ods pdf startpage=now;

proc odstext;
	h1 "Data Issues";
	p  "Leucocytes has either LBORRESU equal to 109/L or cells/uL or a free-text comment in LBCO (multiple variants of 10e3/uL).";
	p  "One entry in LBCO is not 10E3/UL but 10E3/L. This is probably a data entry error.";
	p  "Magnesium has LBORRESU5 equal to mg/dL or nmol/L, but sometimes there is no unit.";
	p  "Neutrophils has LBORREESU equal to 109/L or cells/uL, but sometimes there is no unit.";
	p  "Laboratory values are always judged NCS Abnormal or CS Abnormal, but never Normal.";
	p  "PC_DEVIATION is often equal to Yes even if there is no delay.";
	p  "PC_DELAY does not take into account the date. So time differences between two different days are wrong.";
	p  "PC_DEVIATION is sometimes equal to No even if sampling was done several hours earlier.";
	p  "PC_DEVIATION seems to suffer from a confusion between AM and PM in one case (as the deviation is 12 x 60 = 720 min).";
	p 	"U-Leucocytes always has the unit Leu/uL. However, its values are not always numerical but also +, NEG, N. Once, the value is in the free-text LCBO (NEGATIVE).";
run;

proc document name=tables;   replay; quit;
proc document name=figures;  replay; quit;
proc document name=listings; replay; quit;

ods pdf close;
