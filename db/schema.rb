# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170326021750) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

# Could not dump table "divisions" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

  create_table "governments", primary_key: "slug", id: :text, force: :cascade do |t|
    t.text "name"
    t.index ["slug"], name: "index_governments_on_slug", unique: true, using: :btree
  end

# Could not dump table "harris_comm_precincts" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "hcc" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "hou_city_council" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

  create_table "officials", primary_key: "slug", id: :text, force: :cascade do |t|
    t.text "name"
    t.date "born"
    t.text "photo"
    t.text "third_party_photo_url"
    t.text "url"
    t.json "addresses"
    t.text "party"
    t.json "phones"
    t.json "urls"
    t.json "emails"
    t.json "channels"
    t.index ["slug"], name: "index_officials_on_slug", unique: true, using: :btree
  end

  create_table "precinct_data", id: false, force: :cascade do |t|
    t.string "fips",   limit: 10
    t.string "county", limit: 255
    t.string "prec",   limit: 10
    t.string "pctkey", limit: 20
    t.string "planc",  limit: 20
    t.string "planh",  limit: 20
    t.string "plans",  limit: 20
    t.string "plane",  limit: 20
  end

  create_table "spatial_ref_sys", primary_key: "srid", id: :integer, force: :cascade do |t|
    t.string  "auth_name", limit: 256
    t.integer "auth_srid"
    t.string  "srtext",    limit: 2048
    t.string  "proj4text", limit: 2048
  end

  create_table "terms", force: :cascade do |t|
    t.text "division_slug"
    t.text "official_slug"
    t.text "name"
    t.date "start_date"
    t.date "end_date"
    t.index ["division_slug", "official_slug"], name: "index_terms_on_division_slug_and_official_slug", using: :btree
    t.index ["end_date"], name: "index_terms_on_end_date", using: :btree
    t.index ["start_date"], name: "index_terms_on_start_date", using: :btree
  end

# Could not dump table "tx_cities" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "tx_counties" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "tx_house_districts" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "tx_isds" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "tx_precincts" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "tx_sboe_districts" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "tx_senate_districts" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "us_house_districts" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

# Could not dump table "us_states" because of following StandardError
#   Unknown type 'geometry(MultiPolygon,4326)' for column 'geom'

end
