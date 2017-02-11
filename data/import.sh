#!/bin/bash

set -eo pipefail

DBNAME=houvote_data
DBHOST=db

function sql () {
  CMD="$1"
  psql -U postgres -h $DBHOST -d $DBNAME -c "$CMD"
}

function ssql () {
  CMD=""
  while read -r line; do CMD+="$line "; done;
  psql -U postgres -h $DBHOST -d $DBNAME -c "$CMD"
}

function download_unzip () {
  URL=$1
  FILE=$2
  wget --no-clobber $1
  unzip $2 -d out
}

function shp_import () {
  URL=$1
  ZIP=$2
  DIR=$3
  SHP=$4
  SRID=$5
  TABLE=$6
  download_unzip $URL $ZIP

  if [ -z "$DIR" ]; then
    OUTPATH="out/$SHP"
  else
    OUTPATH="out/$DIR/$SHP"
  fi

  shp2pgsql -I -s $SRID $OUTPATH $TABLE | psql -U postgres -h $DBHOST -d $DBNAME
  rm -rf out
}

# Create database
# ===============

psql -U postgres -h $DBHOST -c "DROP DATABASE $DBNAME;" || true
psql -U postgres -h $DBHOST -c "CREATE DATABASE $DBNAME;"
sql "CREATE EXTENSION postgis;"
ssql <<SQL
CREATE TABLE IF NOT EXISTS governments (
  slug varchar(255) not null primary key,
  name varchar(255),
  level varchar(255),
  category varchar(255),
  geom geometry(MultiPolygon,4269)
);
SQL

# Import US house districts
# =========================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.zip" \
  "" \
  "cb_2015_us_cd114_500k.shp" \
  4269 \
  us_house_districts

# Copy Texas house districts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('us-house-115-district-', cd114fp) AS slug,
    CONCAT('115th Congress US house district ', cd114fp) AS name,
    'federal' AS level,
    'US House' AS category,
    geom
  FROM us_house_districts
  WHERE statefp = '48'
);
SQL


# Create US Senate districts
# ==========================

ssql <<SQL
INSERT INTO governments
(slug, name, level, category)
VALUES
('us-senate-seat-1', 'US Senate Seat 1', 'federal', 'US Senate'),
('us-senate-seat-2', 'US Senate Seat 2', 'federal', 'US Senate');
SQL


# Import TX Senate districts

shp_import \
  "ftp://ftpgis1.tlc.state.tx.us/DistrictViewer/Senate/PlanS172.zip" \
  "PlanS172.zip" \
  "PLANS172" \
  "PLANS172.shp" \
  4269 \
  tx_senate_districts

# Copy Texas senate districts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('tx-senate-district-', district) AS slug,
    CONCAT('Texas senate district ', district) AS name,
    'state' AS level,
    'Texas state senate' AS category,
    geom
  FROM tx_senate_districts
);
SQL


sql "\\COPY governments TO governments.csv CSV HEADER"
