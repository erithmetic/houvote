#!/bin/bash

set -euo pipefail

DBNAME=houvote_data
DBHOST=db

function sql () {
  echo "$1" | psql -U postgres -h $DBHOST -d $DBNAME
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

echo "CREATE DATABASE $DBNAME;" | psql -U postgres -h $DBHOST
sql "CREATE EXTENSION postgis;"
sql <<SQL
CREATE TABLE IF NOT EXISTS areas (
  slug varchar(255) not null primary key,
  name varchar(255),
  geom geometry(MultiPolygon,4269)
);
SQL

# Import US Senate districts
# ==========================


# Import US house districts
# =========================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.shp" \
  4269

# Copy Texas districts to areas






pg_dump -U postgres -h $DBHOST -t areas -f areas.sql $DBNAME 
