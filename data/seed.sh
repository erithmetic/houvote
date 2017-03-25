#!/bin/bash

set -eo pipefail

if [ "$1" == "production" ]; then
  DBNAME=houvote_production
  DBHOST=db
else
  DBNAME=houvote_development
  DBHOST=db
fi


function sql () {
  CMD=""
  while read -r line; do CMD+="$line "; done;
  psql -U postgres -h $DBHOST -d $DBNAME -c "$CMD"
}

sql <<SQL
\\COPY governments (slug,name,level,category,geom) FROM governments.csv WITH CSV HEADER
SQL

sql <<SQL
UPDATE governments SET geom_webmercator = ST_Transform(geom, 4326);
SQL

sql <<SQL
\\COPY people (slug,name,born,photo,third_party_photo_url,url) FROM people.csv WITH CSV HEADER
SQL
