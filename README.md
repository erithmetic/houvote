# README

Houvote

Get info on elected and unelected government

## Structure

<pre>
governments
  slug
  name
  level {special,city,county,state,federal}
  geom

terms
  government_slug
  person_slug
  name            # e.g. chair 1, optional
  start_date
  end_date

people
  slug
  photo_url
  name
  born
</pre>
