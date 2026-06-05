/******************************************************************************/
/*** Section 1: Setup *********************************************************/
/******************************************************************************/

/* clean workspace */

/*
proc datasets library=work kill;
run;
dm 'odsresults; clear';
dm "log; clear; ";
options nosource;
options nonotes;
*/

proc datasets library=work kill nolist; run; quit;
proc catalog catalog=work.formats kill nolist; run; quit;
%symdel _all_ / nowarn;
ods _all_ close;
dm 'odsresults; clear';
dm "log; clear;";
options nosource nonotes;

/* define paths */

/* Specifying the paths to the input directories for the randomisation list (pathRand),
the clinical data (pathClin), and the pharmacokinetic data (pathPhar),
and specifying the path to the output directory for the report (pathOut).*/ 
%let pathRand=C:\Users\arauschenberger\Desktop\Crypto-HIV;
%let pathClin=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-Phase2 Study\4 - Data Management\7-Data transfers\Export files\30-Jul-2025_Franck;
%let pathPhar=I:\Projects folder\CCMS\Crypto-HIV\DNDi-5FC-02-CM (fed study)\4 - Data Management\7-Data transfers\Import files\15032023_Pharmetheus\0131FRM18_DNDi-5FC-02-CM_PK_20230315\0131FRM18_DNDi-5FC-02-CM_PK_20230315;
%let pathOut=C:\Users\arauschenberger\Desktop\Crypto-HIV;
