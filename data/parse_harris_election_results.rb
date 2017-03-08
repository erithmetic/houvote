require 'csv'
require 'pry'

sections = {}
section = nil
headers = []
$line = []

lines = File.readlines 'canvass.txt', mode: 'r:UTF-8'

SKIPS = [
  /Total Number of Voters/,
  /Precincts Reporting/,
  /Continued/,
  /Harris County, Texas/,
  /Page \d/
]

class Header < Struct.new(:start, :stop, :title)

  def overlaps?(start_2, stop_2)
    (start <= start_2 && start_2 <= stop) ||
    (start <= stop_2 && stop_2 <= stop) ||
    (start_2 <= start && start <= stop_2) ||
    (start_2 <= stop && stop <= stop_2)
  end

end

while lines.any? do
  row = lines.shift

  # TOP SECTION - Get section name, then keep reading lines until we get to
  # headers
  if row =~ /Canvass Report/
    section = nil
    headers_columns = []
    headers = []
    next
  end
  next if SKIPS.any? { |skip| row =~ skip }

  # SKIP BLANK LINE
  next if row.strip == ''

  # GET SECTION NAME
  if row !~ /^\d/ && section.nil?
    section = row.strip.downcase.gsub(/[\s,_]+/, '_').gsub(/\./, '')
    sections[section] ||= []
    next
  end

  # SKIP "Continued" garbage
  next if row =~ /Continued/

  # HEADERS OMFG
  if row !~ /^\d/
    next if sections[section].any?

    cols = row.split(/\s{2,}/).map(&:strip).reject { |c| c.length < 1 }
    rest = row
    index = 0
    cols.each do |col|
      left = rest.index(col)
      right = left + col.length
      rest.sub! /#{col}/, ' ' * col.length

      if header = headers.find { |h| h.overlaps?(left, right) }
        header.start = [header.start, left].min
        header.stop = [header.stop, right].max
        header.title += " #{col}"
      else
        headers << Header.new(left, right, col)
      end

      index += col.length
    end

    next
  end

  # ALL HEADERS CONSUMED, WRITE THEM
  if headers.any?
    sections[section] << headers.map(&:title)
    headers = []
  end

  # PARSE DATA LINE
  vals = row.split(/\s+/)
  sections[section] << vals
end

sections.each do |section, rows|
  CSV.open("harris_#{section}.csv", 'w') do |csv|
    rows.each do |row|
      csv << row
    end
  end
end

