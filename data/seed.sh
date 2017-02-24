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


# Add TX's two US senators
sql <<SQL
INSERT INTO people (slug, name, born, url, third_party_photo_url)
('ted-cruz', 'Ted Cruz', '1970-12-22', 'https://www.cruz.senate.gov', 'https://upload.wikimedia.org/wikipedia/commons/8/87/Ted_Cruz%2C_official_portrait%2C_113th_Congress.jpg'),
('john-cornyn', 'John Cornyn',)
ON CONFLICT DO UPDATE;
SQL
sql <<SQL
INSERT INTO terms (slug, name, born, url, third_party_photo_url)
('ted-cruz', 'Ted Cruz', '1970-12-22', 'https://www.cruz.senate.gov', 'https://upload.wikimedia.org/wikipedia/commons/8/87/Ted_Cruz%2C_official_portrait%2C_113th_Congress.jpg'),
('john-cornyn', 'John Cornyn',)
ON CONFLICT DO UPDATE;
SQL


# Download list of TX state senators

wget "https://openstates.org/api/v1/legislators/?state=tx&chamber=upper"
