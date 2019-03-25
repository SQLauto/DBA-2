/*
Run in the OTFP database.
This script deletes 103 duplicate records in otfp.BatchQueue
It deletes them by Id (previously established), so is re-runnable. Second and subsequent runs will do nothing

No rollback script is necessary as the relevant data is actually still in the table
*/

PRINT 'Processing starting';

USE OTFP;

BEGIN TRAN

DECLARE @badId TABLE ( Id bigint NOT NULL );

INSERT @badId VALUES  
  ( 22190927 )            -- duplicate of Id 22190790
, ( 22190928 )            -- duplicate of Id 22190791
, ( 22190929 )            -- duplicate of Id 22190792
, ( 22190930 )            -- duplicate of Id 22190793
, ( 22190931 )            -- duplicate of Id 22190794
, ( 22190932 )            -- duplicate of Id 22190795
, ( 22190933 )            -- duplicate of Id 22190796
, ( 22190934 )            -- duplicate of Id 22190797
, ( 22190935 )            -- duplicate of Id 22190798
, ( 22190936 )            -- duplicate of Id 22190799
, ( 22190937 )            -- duplicate of Id 22190800
, ( 22190938 )            -- duplicate of Id 22190801
, ( 22190939 )            -- duplicate of Id 22190802
, ( 22190940 )            -- duplicate of Id 22190803
, ( 22190941 )            -- duplicate of Id 22190804
, ( 22190942 )            -- duplicate of Id 22190805
, ( 22190943 )            -- duplicate of Id 22190806
, ( 22190944 )            -- duplicate of Id 22190807
, ( 22190945 )            -- duplicate of Id 22190808
, ( 22190946 )            -- duplicate of Id 22190809
, ( 22190947 )            -- duplicate of Id 22190810
, ( 22190948 )            -- duplicate of Id 22190811
, ( 22190949 )            -- duplicate of Id 22190812
, ( 22190950 )            -- duplicate of Id 22190813
, ( 22190951 )            -- duplicate of Id 22190814
, ( 22190952 )            -- duplicate of Id 22190815
, ( 22190953 )            -- duplicate of Id 22190816
, ( 22190954 )            -- duplicate of Id 22190817
, ( 22190955 )            -- duplicate of Id 22190818
, ( 22190956 )            -- duplicate of Id 22190819
, ( 22190957 )            -- duplicate of Id 22190820
, ( 22190958 )            -- duplicate of Id 22190821
, ( 22190959 )            -- duplicate of Id 22190822
, ( 22190960 )            -- duplicate of Id 22190823
, ( 22190961 )            -- duplicate of Id 22190824
, ( 22190962 )            -- duplicate of Id 22190825
, ( 22190963 )            -- duplicate of Id 22190826
, ( 22190964 )            -- duplicate of Id 22190827
, ( 22190965 )            -- duplicate of Id 22190828
, ( 22190966 )            -- duplicate of Id 22190829
, ( 22190967 )            -- duplicate of Id 22190830
, ( 22190968 )            -- duplicate of Id 22190831
, ( 22190969 )            -- duplicate of Id 22190832
, ( 22190970 )            -- duplicate of Id 22190833
, ( 22190971 )            -- duplicate of Id 22190834
, ( 22190972 )            -- duplicate of Id 22190835
, ( 22190973 )            -- duplicate of Id 22190836
, ( 22190974 )            -- duplicate of Id 22190837
, ( 22190975 )            -- duplicate of Id 22190838
, ( 22190976 )            -- duplicate of Id 22190839
, ( 22190977 )            -- duplicate of Id 22190840
, ( 22190978 )            -- duplicate of Id 22190841
, ( 22190979 )            -- duplicate of Id 22190842
, ( 22190980 )            -- duplicate of Id 22190843
, ( 22190981 )            -- duplicate of Id 22190844
, ( 22190982 )            -- duplicate of Id 22190845
, ( 22190983 )            -- duplicate of Id 22190846
, ( 22190984 )            -- duplicate of Id 22190847
, ( 22190985 )            -- duplicate of Id 22190848
, ( 22190986 )            -- duplicate of Id 22190849
, ( 22190987 )            -- duplicate of Id 22190850
, ( 22190988 )            -- duplicate of Id 22190851
, ( 22190989 )            -- duplicate of Id 22190852
, ( 22190990 )            -- duplicate of Id 22190853
, ( 22190991 )            -- duplicate of Id 22190854
, ( 22190992 )            -- duplicate of Id 22190855
, ( 22190993 )            -- duplicate of Id 22190856
, ( 22190994 )            -- duplicate of Id 22190857
, ( 22190995 )            -- duplicate of Id 22190858
, ( 22190996 )            -- duplicate of Id 22190859
, ( 22190997 )            -- duplicate of Id 22190860
, ( 22190998 )            -- duplicate of Id 22190861
, ( 22190999 )            -- duplicate of Id 22190862
, ( 22191000 )            -- duplicate of Id 22190863
, ( 22191001 )            -- duplicate of Id 22190864
, ( 22191002 )            -- duplicate of Id 22190865
, ( 22191003 )            -- duplicate of Id 22190866
, ( 22191004 )            -- duplicate of Id 22190867
, ( 22191005 )            -- duplicate of Id 22190868
, ( 22191006 )            -- duplicate of Id 22190869
, ( 22191007 )            -- duplicate of Id 22190870
, ( 22191008 )            -- duplicate of Id 22190871
, ( 22191009 )            -- duplicate of Id 22190872
, ( 22191010 )            -- duplicate of Id 22190873
, ( 22191011 )            -- duplicate of Id 22190874
, ( 22191012 )            -- duplicate of Id 22190875
, ( 22191013 )            -- duplicate of Id 22190876
, ( 22191014 )            -- duplicate of Id 22190877
, ( 22191015 )            -- duplicate of Id 22190878
, ( 22191016 )            -- duplicate of Id 22190879
, ( 22191017 )            -- duplicate of Id 22190880
, ( 22191018 )            -- duplicate of Id 22190881
, ( 22191019 )            -- duplicate of Id 22190882
, ( 22191020 )            -- duplicate of Id 22190883
, ( 22191021 )            -- duplicate of Id 22190884
, ( 22191022 )            -- duplicate of Id 22190885
, ( 22191023 )            -- duplicate of Id 22190886
, ( 22191024 )            -- duplicate of Id 22190887
, ( 22191025 )            -- duplicate of Id 22190888
, ( 22191026 )            -- duplicate of Id 22190889
, ( 22191027 )            -- duplicate of Id 22190890
, ( 22191028 )            -- duplicate of Id 22190891
, ( 22191029 )            -- duplicate of Id 22190892
; 

DECLARE @rowcount int;

DELETE OTFP.otfp.BatchQueue WHERE Id IN ( SELECT Id FROM @badId );

SET @rowcount = @@ROWCOUNT;

IF @rowcount = 103
	BEGIN
	PRINT '103 records deleted as expected, COMMITting';
	COMMIT;
	END
ELSE
	BEGIN
	PRINT 'Was expected 103 records deleted, got ' + CAST(@rowcount AS VARCHAR(10)) + ', so rolling back';
	ROLLBACK;
	END

PRINT 'Processing complete';
