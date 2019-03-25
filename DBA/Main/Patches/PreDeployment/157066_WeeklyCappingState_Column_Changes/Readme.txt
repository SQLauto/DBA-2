The intention of these 8 scripts is to remove a delay to the R89 Deployment that would be caused by a patching script
in Travelstore and Travelstore_CPC that would add at leat 1h30 minutes onto the release.

There are 8 scripts provided 1a,1b,2a,2b,3a,3b,4a,4b

The division into a(Travelstore_cpc) and b(Travelstore) is an indication that a and b can be run in seperate sql windows at the same time.

The intention of the patching script is altering a number of columns in travel.weeklycappingstate and archive.weeklycappingstate.
In the patching script this is done one Alter statement at a time and is a log heavy operation and is a timely operation when this is done on multiple fields.

This approach for each of Travelstore and Travelstore_cpc is to:

Stage 1 - During the day before the release
1) Create a travel.weeklycappingstate_NEW table and during the day before the release with the correct data types
2) Copy data into weeklycappingstate_NEW table one partition at a time with a manual checkpoint run after every 5 partitions.

Stage 2 - Once the System has been shutdown and differential backups are being taken
3) Run the syncing scripts to merge data that is new or changed.
4) Run Renaming script that renames 
	i. current(travel.weeklycappingstate) to travel.weeklycappingstate_OLD 
	ii. travel.weeklycappingstate_NEW to  travel.weeklycappingstate

NB! 
We have not included archive tables into these scripts as both tables in each database are empty. The patching script will take care of their datatype changes.
We will be conservative and leave the _OLD table in the database as a precaution. We will run a script in R90 to drop this table.






