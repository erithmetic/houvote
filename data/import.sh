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

  echo $URL
  echo $FILE

  if [ ! -e $FILE ]; then
    echo "Downloading $URL"
    curl -L "$URL" > "$FILE"
  fi

  echo "Unzipping $FILE"
  unzip $FILE -d out
}

function shp_import () {
  URL=$1
  ZIP=$2
  DIR=$3
  SRID=$4
  TABLE=$5

  rm -rf out/*

  download_unzip $URL $ZIP

  CWD=$(pwd)

  if [ -z "$DIR" ]; then
    OUTPATH=$(ls $CWD/out/*.shp)
  else
    OUTPATH=$(ls $CWD/out/$DIR/*.shp)
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
  geom geometry(MultiPolygon,4326)
);
SQL


# Import US States
# ================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_state_20m.zip" \
  "cb_2015_us_state_20m.zip" \
  "" \
  "4269:4326" \
  us_states


# Import US house districts
# =========================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.zip" \
  "" \
  "4269:4326" \
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
(slug, name, level, category, geom)
VALUES
('us-senate-seat-1', 'US Senate Seat 1', 'federal', 'US Senate', (SELECT geom FROM us_states where statefp = '48')),
('us-senate-seat-2', 'US Senate Seat 2', 'federal', 'US Senate', (SELECT geom FROM us_states where statefp = '48'));
SQL


# Create TX State positions
# =========================

ssql <<SQL
INSERT INTO governments
(slug, name, level, category, geom)
VALUES
('tx-governor', 'Governor of Texas', 'state', 'Governor', (SELECT geom FROM us_states where statefp = '48')),
('tx-lt-governor', 'Lieutenant Governor of Texas', 'state', 'Governor', (SELECT geom FROM us_states where statefp = '48')),
('tx-comptroller', 'Texas Comptroller of Public Accounts', 'state', 'Comptroller', (SELECT geom FROM us_states where statefp = '48')),
('tx-attorney-general', 'Attorney General', 'state', 'Attorney General', (SELECT geom FROM us_states where statefp = '48')),
('tx-general-land-office', 'Texas General Land Office', 'state', 'General Land Office', (SELECT geom FROM us_states where statefp = '48')),
('tx-department-of-agriculture', 'Texas Department of Agriculture', 'state', 'Department of Agriculture', (SELECT geom FROM us_states where statefp = '48')),
('tx-railroad-commission', 'Texas Railroad Commission', 'state', 'Railroad Commission', (SELECT geom FROM us_states where statefp = '48'));
SQL


# Import TX Senate districts
# ==========================

shp_import \
  "ftp://ftpgis1.tlc.state.tx.us/DistrictViewer/Senate/PlanS172.zip" \
  "PlanS172.zip" \
  "PLANS172" \
  "3081:4326" \
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


# Import TX House districts
# =========================

shp_import \
  "ftp://ftpgis1.tlc.state.tx.us/DistrictViewer/House/PlanH358.zip" \
  "PlanH358.zip" \
  "PLANH358" \
  "3081:4326" \
  tx_house_districts

# Copy Texas house districts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('tx-house-district-', district) AS slug,
    CONCAT('Texas house district ', district) AS name,
    'state' AS level,
    'Texas state house of representatives' AS category,
    geom
  FROM tx_house_districts
);
SQL


# Import state board of education districts
# =========================================

shp_import \
  "ftp://ftpgis1.tlc.state.tx.us/DistrictViewer/SBOE/PlanE120.zip" \
  "PlanE120.zip" \
  "PLANE120" \
  "3081:4326" \
  tx_sboe_districts

# Copy Texas board of education districts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('tx-sboe-district-', district) AS slug,
    CONCAT('Texas board of education district ', district) AS name,
    'state' AS level,
    'Texas board of education' AS category,
    geom
  FROM tx_sboe_districts
);
SQL


# Import counties
# ===============

shp_import \
  "https://data.texas.gov/api/geospatial/48ag-x9aa?method=export&format=Shapefile" \
  "TexasCounties.zip" \
  "" \
  "4269:4326" \
  tx_counties

# Copy Texas counties to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('tx-county-', fips_code) AS slug,
    CONCAT(name, ' County') AS name,
    'county' AS level,
    'County' AS category,
    geom
  FROM tx_counties
);
SQL


# Import voting precincts
# =======================
wget --no-clobber ftp://ftpgis1.tlc.state.tx.us/2011_Redistricting_Data/Precincts/Data/Precinct_Districts.xlsx

xlsx2csv Precinct_Districts.xlsx > precint_data.csv

ssql <<SQL
CREATE TABLE precinct_data (
  fips VARCHAR(10), 
  county VARCHAR(255),
  prec VARCHAR(10), 
  pctkey VARCHAR(20), 
  planc VARCHAR(20), 
  planh VARCHAR(20), 
  plans VARCHAR(20), 
  plane VARCHAR(20)
);
SQL

sql "\\COPY precinct_data FROM precinct_data.csv CSV HEADER"

shp_import \
  "ftp://ftpgis1.tlc.state.tx.us/2011_Redistricting_Data/Precincts/Geography/Precincts.zip" \
  "Precincts.zip" \
  "" \
  "3081:4326" \
  tx_precincts

# Copy voting precincts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('tx-precinct-', pctkey) AS slug,
    (SELECT CONCAT(INITCAP(LOWER(pd.county)), ' County Precinct ', prec)
     FROM precinct_data pd
     WHERE pd.pctkey = tp.pctkey) AS name,
    'state' AS level,
    'Voting Precinct' AS category,
    geom
  FROM tx_precincts tp
);
SQL


# Import ISDs
# ===========

shp_import \
  "https://opendata.arcgis.com/datasets/e115fed14c0f4ca5b942dc3323626b1c_0.zip" \
  "e115fed14c0f4ca5b942dc3323626b1c_0.zip" \
  "" \
  "4269:4326" \
  tx_isds

# Copy school districts to governments
ssql <<SQL
INSERT INTO governments (
  SELECT CONCAT('tx-isd-', LOWER(name2), '-', district) AS slug,
    name,
    'state' AS level,
    'School District' AS category,
    geom
  FROM tx_isds tp
);
SQL


# Harris County 2016 precinct results
# ===================================

wget --no-clobber http://www.harrisvotes.com/HISTORY/20161108/canvass/canvass.pdf
pdftotext -layout canvass.pdf canvass.txt
ruby parse_harris_election_results.rb harris/2016_11 canvass.txt
ruby import_harris_candidates.rb harris/2016_11
# => elections.csv
# => people.csv
# => terms.csv


# Ft Bend results

#wget --no-clobber http://results.enr.clarityelections.com/TX/Fort_Bend/64723/184359/reports/detailxls.zip
#unzip detailxls.zip

sql "\\COPY governments TO governments.csv CSV HEADER"

cat governments.csv | awk -F , '{ print $1; }' | tail -n +2 | xargs -I {} touch meta/{}.yml
