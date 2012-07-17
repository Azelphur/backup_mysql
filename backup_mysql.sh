#!/bin/bash

# MySQL username
USER="root"

# MySQL Password
PASS="secret"

# Location to store backups including trailing / you can use strftime variables here. If you intend to backup more than daily you will need to change this.
STORAGE="/path/to/backups/backups/sql/%Y/%B/%d/"

# List of databases to ignore. Ignore "Database" as it's the table header and not an actual database, and information_schema as it isn't lockable and is just metadata
IGNORELIST=( "Database" "information_schema" "mysql" )

# You don't need to edit anything beyond this point

# Where is the mysql executable? (usually /usr/bin/mysql)
MYSQL=($which mysql)

# Get a list of databases
DATABASES=`echo "SHOW DATABASES;" | $MYSQL -u$USER -p$PASS`

function isignored() {
	for IGNORED in "${IGNORELIST[@]}"
	do
		if [ "$1" == "$IGNORED" ]
		then
			return 0
		fi
	done
	return 1
}

echo "Backup started at `date`"
# Loop through list of databases
for DATABASE in $DATABASES
do
	# Check if we are ignoring this database
	if ( isignored "$DATABASE" )
	then
		continue
	fi

	TABLES=$(mysql -u$USER -p$PASS -e "SHOW TABLES IN $DATABASE;"  | sed -e 1d -e "s/^| (.*) |$/\0/")
	echo "Backing up $DATABASE"
	START=`date +%s`
	for TABLE in $TABLES
	do
		# Create the directories if needed
		mkdir -p "`date +$STORAGE`$DATABASE/"
		FILE="`date +$STORAGE`$DATABASE/$TABLE.sql.bz2"
		# Perform the backup
		mysqldump -u$USER -p$PASS $DATABASE $TABLE | nice -n 19 ionice -c 3 bzip2 -cq9 > $FILE
	done
	echo "Backed up $DATABASE in $((`date +%s`-$START)) seconds"
done
echo "Backup complete at `date`"
