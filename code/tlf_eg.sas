
/******************************************************************************/
/*** electrocardiogram ********************************************************/
/******************************************************************************/

%put --- electrocardiogram ---;

%order_levels(code=EG,var=VISIT);
%order_levels(code=EG,var=EGSTRESC1);
/*%order_levels(code=EG,var=EGTEST);*/
%as_numeric(code=EG,var=EGORRES);
/*%sub_per(code=EG);*/
%add_unit(code=EG);
%label_vars(code=EG);

/* table: electrocardiogram, at day 1*/ 
ods document name=tables(update);
%tabulate(code=EG,visit="Day 1");
ods document close;

/* listing: abnormal EG at day 1*/
ods document name=listings(update);
%list_abnormal(code=EG,check_visit='Day 1',show_visit='Day 1');
ods document close;
