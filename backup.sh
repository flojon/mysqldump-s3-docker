#!/bin/sh
# Dump all databases and upload to S3 bucket
# Adapted from https://gist.github.com/oodavid/2206527

if [ -z "${MYSQL_HOST}" ]; then
  echo "Missing MYSQL_HOST envoronment variable"
  exit 1
fi
if [ -z "${MYSQL_USER}" ]; then
  echo "Missing MYSQL_USER envoronment variable"
  exit 1
fi
if [ -z "${MYSQL_PASSWORD}" ]; then
  echo "Missing MYSQL_PASSWORD envoronment variable"
  exit 1
fi
if [ -z "${S3_ACCESS_KEY}" ]; then
  echo "Missing S3_ACCESS_KEY envoronment variable"
  exit 1
fi
if [ -z "${S3_SECRET_KEY}" ]; then
  echo "Missing S3_SECRET_KEY envoronment variable"
  exit 1
fi
if [ -z "${S3_BUCKET}" ]; then
  echo "Missing S3_BUCKET envoronment variable"
  exit 1
fi

mysql_connection="-h ${MYSQL_HOST} -u ${MYSQL_USER:-root} -p${MYSQL_PASSWORD}"
s3_connection="--access_key=${S3_ACCESS_KEY} --secret_key=${S3_SECRET_KEY}"
if [ -n "${S3_ENDPOINT}" ]; then
  s3_connection="$s3_connection --host=${S3_ENDPOINT} --host-bucket=%(bucket)s.${S3_ENDPOINT}"
fi

# Timestamp
stamp=`date +"%Y%m%d_%H%M"`

# List all the databases
databases=`mysql $mysql_connection -e "SHOW DATABASES;" | tr -d "| " | grep -v "\(Database\|information_schema\|performance_schema\|mysql\|test\)"`

# Feedback
echo -e "Dumping to \e[1;32ms3://${S3_BUCKET}${S3_BACKUP_PATH:-/}\e[00m"

# Loop the databases
for db in $databases; do

  # Define our filenames
  filename="$db_$stamp.sql.gz"
  object="s3://${S3_BUCKET}${S3_BACKUP_PATH:-/}$db/$filename"

  # Feedback
  echo -e "\e[1;34m$db\e[00m"

  # Dump and zip
  mysqldump $mysql_connection ${MYSQLDUMP_EXTRA_ARGS} --databases "$db" \
    | gzip -c \
    | s3cmd -q $s3_connection put - $object

done;

# Jobs a goodun
echo -e "\e[1;32mJobs a goodun\e[00m"