# README

Houvote

Get info on elected and unelected government

## Structure

governments
  slug
  name
  level {special,city,county,state,federal}
  geom

offices
  government_slug
  person_slug
  name            # e.g. chair 1, optional

persons
  slug
  fname
  mname
  lname
  born

