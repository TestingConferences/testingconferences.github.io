#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'date'
require 'digest'
require 'yaml'

DATA_FILE = File.expand_path('../_data/current.yml', __dir__)
OUTPUT_FILE = File.expand_path('../calendar.ics', __dir__)

MONTH_PATTERN = '(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)'

def normalize_month(name)
  case name.to_s.downcase
  when 'jan' then 'January'
  when 'feb' then 'February'
  when 'mar' then 'March'
  when 'apr' then 'April'
  when 'may' then 'May'
  when 'jun' then 'June'
  when 'jul' then 'July'
  when 'aug' then 'August'
  when 'sep', 'sept' then 'September'
  when 'oct' then 'October'
  when 'nov' then 'November'
  when 'dec' then 'December'
  else
    name.to_s.capitalize
  end
end

def date_from_parts(month_name, day, year)
  month = Date::MONTHNAMES.index(normalize_month(month_name))
  return nil unless month

  Date.new(year.to_i, month, day.to_i)
rescue ArgumentError
  nil
end

def parse_date_range(raw)
  return nil unless raw.is_a?(String)

  s = raw.strip.gsub(/[–—]/, '-')

  # "April 26 - May 1, 2026"
  if (m = s.match(/\A(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(#{MONTH_PATTERN})\s*(\d{1,2}),?\s*(\d{4})\z/i))
    start_date = date_from_parts(m[1], m[2], m[5])
    end_date = date_from_parts(m[3], m[4], m[5])
    return [start_date, end_date] if start_date && end_date
  end

  # "September 21-22, 2026"
  if (m = s.match(/\A(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(\d{1,2}),?\s*(\d{4})\z/i))
    start_date = date_from_parts(m[1], m[2], m[4])
    end_date = date_from_parts(m[1], m[3], m[4])
    return [start_date, end_date] if start_date && end_date
  end

  # "March 4-5 March, 2026" (legacy/typo-tolerant format)
  if (m = s.match(/\A(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(\d{1,2})\s+(#{MONTH_PATTERN}),?\s*(\d{4})\z/i))
    start_date = date_from_parts(m[1], m[2], m[5])
    end_date = date_from_parts(m[4], m[3], m[5])
    return [start_date, end_date] if start_date && end_date
  end

  # "April 3, 2026"
  if (m = s.match(/\A(#{MONTH_PATTERN})\s+(\d{1,2}),?\s*(\d{4})\z/i))
    day = date_from_parts(m[1], m[2], m[3])
    return [day, day] if day
  end

  # Final fallback for unusual formats
  parsed = Date.parse(s)
  [parsed, parsed]
rescue ArgumentError
  nil
end

def strip_html(text)
  CGI.unescapeHTML(text.to_s.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip)
end

def escape_ical(text)
  text.to_s
      .gsub(/([\\;,])/, '\\\\\1')
      .gsub(/\r\n?|\n/, '\\n')
end

def fold_ical_line(line, limit = 75)
  bytes = line.dup
  result = +''

  while bytes.bytesize > limit
    result << bytes.byteslice(0, limit) << "\r\n "
    bytes = bytes.byteslice(limit..)
  end

  result << bytes.to_s
  result
end

def property(name, value)
  fold_ical_line("#{name}:#{value}")
end

unless File.exist?(DATA_FILE)
  warn "Could not find #{DATA_FILE}"
  exit 1
end

conferences = YAML.safe_load(File.read(DATA_FILE))
unless conferences.is_a?(Array)
  warn "Expected #{DATA_FILE} to contain a YAML array"
  exit 1
end

generated_utc = Time.now.utc
dtstamp = generated_utc.strftime('%Y%m%dT%H%M%SZ')

lines = []
lines << 'BEGIN:VCALENDAR'
lines << 'VERSION:2.0'
lines << 'CALSCALE:GREGORIAN'
lines << 'PRODID:-//TestingConferences.org//Conference Calendar//EN'
lines << property('X-WR-CALNAME', escape_ical('Testing Conferences'))
lines << property('X-WR-CALDESC', escape_ical('Software testing conferences from testingconferences.org'))

skipped = []

conferences.each do |conference|
  start_date, end_date = parse_date_range(conference['dates'])
  unless start_date && end_date
    skipped << conference['name']
    next
  end

  uid_source = [
    conference['name'],
    conference['dates'],
    conference['url']
  ].join('|')
  uid = "#{Digest::SHA1.hexdigest(uid_source)}@testingconferences.org"

  description_parts = []
  description_parts << "Dates: #{conference['dates']}" if conference['dates']
  description_parts << "Status: #{strip_html(conference['status'])}" if conference['status']
  description_parts << "URL: #{conference['url']}" if conference['url']

  lines << 'BEGIN:VEVENT'
  lines << property('UID', escape_ical(uid))
  lines << "DTSTAMP:#{dtstamp}"
  lines << "DTSTART;VALUE=DATE:#{start_date.strftime('%Y%m%d')}"
  # RFC5545 all-day DTEND is non-inclusive; add one day.
  lines << "DTEND;VALUE=DATE:#{(end_date + 1).strftime('%Y%m%d')}"
  lines << property('SUMMARY', escape_ical(conference['name']))
  lines << property('LOCATION', escape_ical(conference['location'])) if conference['location']
  lines << property('URL', escape_ical(conference['url'])) if conference['url']
  lines << property('DESCRIPTION', escape_ical(description_parts.join("\n"))) unless description_parts.empty?
  lines << 'END:VEVENT'
end

lines << 'END:VCALENDAR'

File.write(OUTPUT_FILE, "#{lines.join("\r\n")}\r\n")

puts "Wrote #{OUTPUT_FILE} with #{conferences.size - skipped.size} events."
unless skipped.empty?
  warn "Skipped #{skipped.size} events with unparseable dates:"
  skipped.each { |name| warn "  - #{name}" }
end
