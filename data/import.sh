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
  SHP=$3
  SRID=$4
  download_unzip $URL $ZIP
  shp2pgsql -I -s $SRID out/$SHP us_house_districts | psql -U postgres -h $DBHOST -d $DBNAME
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
  geom geometry(MultiPolygon,4269),
  start_date date,
  end_date date
);
SQL

# Import US house districts
# =========================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.shp" \
  4269

# Copy Texas districts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('us-house-115-district-', cd114fp) AS slug,
    CONCAT('115th Congress US house district ', cd114fp) AS name,
    'federal' AS level,
    geom,
    '2017-01-03',
    '2019-01-03'
  FROM us_house_districts
  WHERE statefp = '48'
);
SQL


# "Import" US Senate districts
# ==========================

ssql <<SQL
INSERT INTO governments
(slug, name, level, start_date, end_date)
VALUES
('us-senate-seat-1', 'US Senate Seat 1', 'federal', '2012-01-03', '2018-01-03'),
('us-senate-seat-2', 'US Senate Seat 2', 'federal', '2014-01-03', '2020-01-03');
SQL


sql "\\COPY governments TO governments.csv CSV HEADER"
