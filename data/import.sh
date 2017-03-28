#!/bin/bash

export RAILS_ENV=${RAILS_ENV:-development}

set -eo pipefail
DBNAME=houvote_$RAILS_ENV
DBHOST=db

export DATABASE_URL=postgres://postgres@db/houvote_$RAILS_ENV

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
  SHPFILE=$6

  rm -rf out/*

  download_unzip $URL $ZIP

  CWD=$(pwd)

  BASEDIR=$CWD/out

  if [ -n "$DIR" ]; then
    BASEDIR=$BASEDIR/$DIR
  fi
  
  if [ -z "$SHPFILE" ]; then
    OUTPATH=$(ls $BASEDIR/*.shp)
  else
    OUTPATH=$BASEDIR/$SHPFILE
  fi

  echo "BASEDIR $BASEDIR"
  echo "OUTPATH $OUTPATH"

  shp2pgsql -I -s "$SRID":4326 $OUTPATH $TABLE | psql -U postgres -h $DBHOST -d $DBNAME
  rm -rf out
}


# Map divisions to Google/VIP API IDs
# ===================================
# ruby init.rb


# Create database
# ===============

set -x

rake db:drop
rake db:create
rake db:migrate

set +x


# Import US States
# ================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_state_20m.zip" \
  "cb_2015_us_state_20m.zip" \
  "" \
  "4269" \
  us_states

ssql <<SQL
INSERT INTO governments (slug, name) VALUES
('us', 'United States'),
('tx', 'Texas');
SQL


# Import US house districts
# =========================

shp_import \
  "http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_cd114_500k.zip" \
  "cb_2015_us_cd114_500k.zip" \
  "" \
  4269 \
  us_house_districts

# Copy Texas house districts to divisions
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('us-house-115-tx-district-', cd114fp) AS slug,
    'us' AS government_slug,
    'House' AS category,
    CONCAT('US house Texas district ', cd114fp) AS name,
    geom
  FROM us_house_districts
  WHERE statefp = '48'
);
SQL


# Create US Senate districts
# ==========================

ssql <<SQL
INSERT INTO divisions
(slug, government_slug, category, name, geom)
VALUES
('tx-us-senate-seat-1', 'us', 'Senate', 'Texas US Senate Seat 1', (SELECT geom FROM us_states where statefp = '48')),
('tx-us-senate-seat-2', 'us', 'Senate', 'Texas US Senate Seat 2', (SELECT geom FROM us_states where statefp = '48'));
SQL


# Create TX State positions
# =========================

ssql <<SQL
INSERT INTO divisions
(slug, government_slug, category, name, geom)
VALUES
('tx-governor', 'tx', 'Governor', 'Governor of Texas', (SELECT geom FROM us_states where statefp = '48')),
('tx-lt-governor', 'tx', 'Lieutenant Governor', 'Lieutenant Governor of Texas', (SELECT geom FROM us_states where statefp = '48')),
('tx-comptroller', 'tx', 'Comptroller', 'Texas Comptroller of Public Accounts', (SELECT geom FROM us_states where statefp = '48')),
('tx-attorney-general', 'tx', 'Attorney General', 'Attorney General', (SELECT geom FROM us_states where statefp = '48')),
('tx-general-land-office', 'tx', 'Texas General Land Office', 'General Land Office', (SELECT geom FROM us_states where statefp = '48')),
('tx-department-of-agriculture', 'tx', 'Department of Agriculture', 'Texas Department of Agriculture', (SELECT geom FROM us_states where statefp = '48')),
('tx-railroad-commission', 'tx', 'Railroad Commission', 'Texas Railroad Commission', (SELECT geom FROM us_states where statefp = '48'));
SQL


# Import TX Senate districts
# ==========================

shp_import \
  "ftp://ftpgis1.tlc.state.tx.us/DistrictViewer/Senate/PlanS172.zip" \
  "PlanS172.zip" \
  "PLANS172" \
  3081 \
  tx_senate_districts

# Copy Texas senate districts to divisions
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-senate-district-', district) AS slug,
    'tx' AS government_slug,
    'Senate' AS category,
    CONCAT('Texas Senate District ', district) AS name,
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
  3081 \
  tx_house_districts

# Copy Texas house districts to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-house-district-', district) AS slug,
    'tx' AS government_slug,
    'House of Representatives' AS category,
    CONCAT('Texas House District ', district) AS name,
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
  3081 \
  tx_sboe_districts

# Copy Texas board of education districts to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-sboe-district-', district) AS slug,
    'tx' AS government_slug,
    'State Board of Education' AS category,
    CONCAT('Texas State Board of Education District ', district) AS name,
    geom
  FROM tx_sboe_districts
);
SQL


# Import counties
# ===============

ssql <<SQL
INSERT INTO governments (slug, name) VALUES ('tx-county', 'County');
SQL

shp_import \
  "https://data.texas.gov/api/geospatial/48ag-x9aa?method=export&format=Shapefile" \
  "TexasCounties.zip" \
  "" \
  4269 \
  tx_counties

# Copy Texas counties to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-county-', fips_code) AS slug,
    'tx-county' AS government_slug,
    'County' AS category,
    CONCAT(name, ' County') AS name,
    geom
  FROM tx_counties
);
SQL


# Import Harris County Commissioners' Court Precincts
# ===================================================

shp_import \
  "https://opendatahouston.s3.amazonaws.com/2013-05-14T23:06:32.088Z/precincts-harris.zip" \
  "precincts-harris.zip" \
  "" \
  3081 \
  harris_comm_precincts

# Copy Texas counties to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('harris-county-commissioners-court-', district) AS slug,
    'tx-county' AS government_slug,
    'County Commissioners'' Court' AS category,
    CONCAT('Harris County Commissioners'' Court Distrct ', district) AS name,
    geom
  FROM harris_comm_precincts
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
  3081 \
  tx_precincts

# Copy voting precincts to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-precinct-', REGEXP_REPLACE(pctkey, '[^\w]', '')) AS slug,
    'tx-county' AS government_slug,
    'Voting Precint' AS category,
    (SELECT CONCAT(INITCAP(LOWER(pd.county)), ' County Precinct ', prec)
     FROM precinct_data pd
     WHERE pd.pctkey = tp.pctkey) AS name,
    geom
  FROM tx_precincts tp
);
SQL


# Import TX Cities
# ================

ssql <<SQL
INSERT INTO governments (slug, name) VALUES ('tx-city', 'City');
SQL

shp_import \
  "https://tnris-datadownload.s3.amazonaws.com/d/political-bnd/state/tx/political-bnd_tx.zip" \
  "political-bnd_tx.zip" \
  "txdot-cities" \
  4269 \
  tx_cities \
  txdot-2015-city-poly_tx.shp

# Copy council districts to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT c.slug, 
    'tx-city' AS government_slug,
    'City' AS category,
    CONCAT('City of ', c.name) AS name,
    c.geom
  FROM (
    SELECT CONCAT('tx-city-', REGEXP_REPLACE(LOWER(TRIM(city_nm)), '[^\w]', '-', 'g')) AS slug,
      city_nm AS name,
      ST_MULTI(ST_UNION(geom)) AS geom
    FROM tx_cities
    GROUP BY slug, name
  ) AS c
);
SQL


# Import Houston City Council Districts
# =====================================

shp_import \
  "https://opendata.arcgis.com/datasets/7237db114eeb416cb481f4450d8a0fa6_2.zip" \
  "7237db114eeb416cb481f4450d8a0fa6_2.zip" \
  "" \
  4326 \
  hou_city_council

# Copy council districts to districts
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('hou-city-council-', LOWER(district)) AS slug,
    'tx-city' AS government_slug,
    'City Council' AS category,
    CONCAT('Houston City Council District ', district),
    geom
  FROM hou_city_council hcc
);
SQL
# Add at-large positions
ssql <<SQL
INSERT INTO divisions
(slug, government_slug, category, name, geom)
VALUES
('hou-city-council-at-large-1', 'tx-city', 'City Council', 'Houston City Council At-Large Position 1', (SELECT geom from divisions WHERE slug = 'tx-city-houston')),
('hou-city-council-at-large-2', 'tx-city', 'City Council', 'Houston City Council At-Large Position 2', (SELECT geom from divisions WHERE slug = 'tx-city-houston')),
('hou-city-council-at-large-3', 'tx-city', 'City Council', 'Houston City Council At-Large Position 3', (SELECT geom from divisions WHERE slug = 'tx-city-houston')),
('hou-city-council-at-large-4', 'tx-city', 'City Council', 'Houston City Council At-Large Position 4', (SELECT geom from divisions WHERE slug = 'tx-city-houston'))
SQL


# Import ISDs
# ===========

shp_import \
  "https://opendata.arcgis.com/datasets/e115fed14c0f4ca5b942dc3323626b1c_0.zip" \
  "e115fed14c0f4ca5b942dc3323626b1c_0.zip" \
  "" \
  4269 \
  tx_isds

# Copy school districts to divisions
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-isd-', REGEXP_REPLACE(LOWER(name2), '[^\w]', '-', 'g'), '-', district) AS slug,
    'tx' AS government_slug,
    'School District' AS category,
    name,
    geom
  FROM tx_isds tp
);
SQL


# Import HCC Districts
# ================================

shp_import \
  "http://pdata.hcad.org/GIS/College.exe" \
  "College.exe" \
  "" \
  4269 \
  hcc

# Copy school districts to divisions
ssql <<SQL
INSERT INTO divisions (
  SELECT CONCAT('tx-hcc-', REGEXP_REPLACE(LOWER(name), '[^\w]', '-', 'g')) AS slug,
    'tx-county' AS government_slug,
    'Community College' AS category,
    name,
    geom
  FROM hcc
  WHERE name is not null
);
SQL


# TODO:
# Super Neighborhoods
# http://data.ohouston.org/dataset/city-of-houston-super-neighborhoods
# Management/Utility Districts
# http://data.ohouston.org/dataset/special-districts-in-harris-county
# Other Managment Districts?
# http://data.ohouston.org/dataset/management-districts
# TIRZs
# http://data.ohouston.org/dataset/city-tax-increment-reinvestment-zones-tirz

sql "\\COPY divisions TO divisions.csv CSV HEADER"
cat divisions.csv | awk -F , '{ print $1; }' | tail -n +2 | xargs -I {} touch 'meta/divisions/{}.yml'
sql "\\COPY governments TO governments.csv CSV HEADER"

ruby import_google_civic_api.rb

# Harris County 2016 precinct results
# ===================================

#wget --no-clobber http://www.harrisvotes.com/HISTORY/20161108/canvass/canvass.pdf
#pdftotext -layout canvass.pdf canvass.txt
#ruby parse_harris_election_results.rb harris/2016_11 canvass.txt
#ruby import_harris_candidates.rb harris/2016_11
# => elections.csv
# => officials.csv
# => terms.csv


# Ft Bend results

#wget --no-clobber http://results.enr.clarityelections.com/TX/Fort_Bend/64723/184359/reports/detailxls.zip
#unzip detailxls.zip


echo "DONE!!!"
