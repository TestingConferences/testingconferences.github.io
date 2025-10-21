#!/usr/bin/env ruby
require 'yaml'
require 'date'
require 'fileutils'

DATA_DIR = File.expand_path('../_data', __dir__)
CURRENT_FILE = File.join(DATA_DIR, 'current.yml')

OUTPUT_FILE = File.expand_path('../tmp/pending_updates.yml', __dir__)

if ARGV.empty?
  warn 'Usage: identify_updates.rb YYYY-MM-DD'
  exit 1
end

begin
  today = Date.parse(ARGV[0])
rescue ArgumentError
  warn "Invalid date: #{ARGV[0]}"
  exit 1
end

unless File.exist?(CURRENT_FILE)
  warn "Could not find #{CURRENT_FILE}"
  exit 1
end

current_events = YAML.load_file(CURRENT_FILE)

MONTH_REGEX = /(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)/i

def normalize_month(name)
  case name.downcase
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
    name.capitalize
  end
end

def parse_end_date(range_str)
  return nil if range_str.nil?

  s = range_str.to_s.strip
  s = s.gsub(/[–—]/, '-')

  # Handle ranges like "April 26 - May 1, 2026"
  if (m = s.match(/(\w+)\s+(\d{1,2})\s*-\s*(\w+)\s*(\d{1,2}),?\s*(\d{4})$/))
    month2 = normalize_month(m[3])
    day2 = m[4]
    year = m[5]
    return Date.parse("#{month2} #{day2} #{year}") rescue nil
  end

  # Handle ranges like "September 21-26, 2025"
  if (m = s.match(/(\w+)\s+\d{1,2}\s*-\s*(\d{1,2}),?\s*(\d{4})$/))
    month = normalize_month(m[1])
    day2 = m[2]
    year = m[3]
    return Date.parse("#{month} #{day2} #{year}") rescue nil
  end

  # Handle single day "September 27, 2025"
  if (m = s.match(/(#{MONTH_REGEX})\s+(\d{1,2}),?\s*(\d{4})$/i))
    month = normalize_month(m[1])
    day = m[2]
    year = m[3]
    return Date.parse("#{month} #{day} #{year}") rescue nil
  end

  # Handle formats like "March 4-5 March, 2026"
  if (m = s.match(/(#{MONTH_REGEX})\s+\d{1,2}\s*-\s*(\d{1,2})\s+(#{MONTH_REGEX}),?\s*(\d{4})$/i))
    month = normalize_month(m[3])
    day = m[2]
    year = m[4]
    return Date.parse("#{month} #{day} #{year}") rescue nil
  end

  # Fallback: let Date.parse try entire string
  Date.parse(s) rescue nil
end

def extract_status_dates(status_text)
  return [] if status_text.nil?
  stripped = status_text.to_s.gsub(/<[^>]+>/, ' ')
  results = []

  stripped.scan(/(#{MONTH_REGEX}\s*\d{1,2}(?:\s*-\s*(?:#{MONTH_REGEX})?\s*\d{1,2})?,?\s*\d{4})/i) do |match|
    segment = match.first
    end_date = parse_end_date(segment)
    results << { segment: segment.strip, date: end_date } if end_date
  end

  results
end

updates = []

current_events.each do |event|
  reasons = []

  end_date = parse_end_date(event['dates'])
  if end_date && end_date < today
    reasons << "Event ended on #{end_date}"
  elsif end_date.nil?
    # Keep track if we couldn't parse but date appears to include a year
    reasons << 'Could not parse event end date' if event['dates'].to_s =~ /\d{4}/
  end

  status_dates = extract_status_dates(event['status'])
  status_dates.each do |item|
    if item[:date] && item[:date] < today
      reasons << "Status mentions past date #{item[:date]} (segment: '#{item[:segment]}')"
    end
  end

  unless reasons.empty?
    updates << event.dup
  end
end

FileUtils.mkdir_p(File.dirname(OUTPUT_FILE))

formatted_entries = updates.map do |event|
  yaml = YAML.dump([event])
  lines = yaml.lines
  lines.shift if lines.first&.start_with?('---')
  lines.reject! { |line| line.strip == '...' }
  lines.map!(&:rstrip)
  lines.join("\n")
end

File.open(OUTPUT_FILE, 'w') do |f|
  if formatted_entries.empty?
    f.write("# No events needing attention for #{today}\n")
  else
    f.write(formatted_entries.join("\n\n"))
    f.write("\n")
  end
end

puts "Identified #{updates.size} events needing attention."
puts "Details written to #{OUTPUT_FILE}."
puts 'Preview only; no source files were modified.'