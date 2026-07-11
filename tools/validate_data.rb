#!/usr/bin/env ruby

require 'date'
require 'set'
require 'uri'
require 'yaml'

ROOT = File.expand_path('..', __dir__)

DATA_FILES = {
  '_data/current.yml' => {
    allowed: %w[name location dates url twitter status],
    required: %w[name location dates url],
    order: :ascending,
    strict: true,
    check_tracking: true
  },
  '_data/past.yml' => {
    allowed: %w[name location dates url twitter status video_playlist video_url],
    required: %w[name location dates url],
    order: nil,
    strict: false,
    check_tracking: false
  },
  '_data/closed.yml' => {
    allowed: %w[name location first_date last_date url twitter status],
    required: %w[name location first_date last_date url],
    order: nil,
    strict: true,
    check_tracking: true
  }
}.freeze

MONTH_PATTERN = '(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)'

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

def build_date(month_name, day, year)
  month_index = Date::MONTHNAMES.index(month_name)
  return nil unless month_index

  Date.new(year.to_i, month_index, day.to_i)
rescue ArgumentError
  nil
end

def parse_event_date(value, boundary)
  return value if value.is_a?(Date)
  return nil if value.nil?

  text = value.to_s.strip.gsub(/[–—]/, '-')

  if text =~ /^(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(#{MONTH_PATTERN})\s*(\d{1,2}),?\s*(\d{4})$/i
    start_month = normalize_month(Regexp.last_match(1))
    start_day = Regexp.last_match(2)
    end_month = normalize_month(Regexp.last_match(3))
    end_day = Regexp.last_match(4)
    year = Regexp.last_match(5)
  elsif text =~ /^(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(\d{1,2}),?\s*(\d{4})$/i
    start_month = end_month = normalize_month(Regexp.last_match(1))
    start_day = Regexp.last_match(2)
    end_day = Regexp.last_match(3)
    year = Regexp.last_match(4)
  elsif text =~ /^(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(\d{1,2})\s+(#{MONTH_PATTERN}),?\s*(\d{4})$/i
    start_month = normalize_month(Regexp.last_match(1))
    start_day = Regexp.last_match(2)
    end_month = normalize_month(Regexp.last_match(4))
    end_day = Regexp.last_match(3)
    year = Regexp.last_match(5)
  elsif text =~ /^(#{MONTH_PATTERN})\s+(\d{1,2}),?\s*(\d{4})$/i
    start_month = end_month = normalize_month(Regexp.last_match(1))
    start_day = end_day = Regexp.last_match(2)
    year = Regexp.last_match(3)
  end

  month = boundary == :end ? end_month : start_month
  day = boundary == :end ? end_day : start_day
  build_date(month, day, year)
rescue ArgumentError
  nil
end

def valid_url?(value)
  uri = URI.parse(value.to_s)
  uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
rescue URI::InvalidURIError
  false
end

def has_tracking_source?(value)
  uri = URI.parse(value.to_s)
  URI.decode_www_form(uri.query.to_s).any? do |key, val|
    key == 'utm_source' && val == 'testingconferences'
  end
rescue URI::InvalidURIError
  false
end

errors = []
warnings = []
seen_names = Hash.new { |hash, key| hash[key] = [] }

DATA_FILES.each do |relative_path, rules|
  path = File.join(ROOT, relative_path)
  data = YAML.safe_load(File.read(path), permitted_classes: [Date])

  unless data.is_a?(Array)
    errors << "#{relative_path}: expected a top-level array"
    next
  end

  local_names = Set.new
  previous_date = nil

  data.each_with_index do |event, index|
    label = "#{relative_path}[#{index + 1}]"

    unless event.is_a?(Hash)
      errors << "#{label}: expected a mapping"
      next
    end

    name = event['name'].to_s.strip
    display = name.empty? ? label : "#{relative_path}: #{name}"

    unknown_fields = event.keys - rules[:allowed]
    unless unknown_fields.empty?
      message = "#{display}: unknown fields: #{unknown_fields.join(', ')}"
      rules[:strict] ? errors << message : warnings << message
    end

    rules[:required].each do |field|
      value = event[field]
      next unless value.nil? || value.to_s.strip.empty?

      message = "#{display}: missing required field `#{field}`"
      rules[:strict] ? errors << message : warnings << message
    end

    if !name.empty?
      warnings << "#{display}: duplicate name in #{relative_path}" if local_names.include?(name)
      local_names.add(name)
      seen_names[name] << relative_path
    end

    if event['twitter'].to_s.include?('@')
      errors << "#{display}: twitter value should not include @"
    end

    if event.key?('url')
      url = event['url']
      errors << "#{display}: url is not a valid HTTP(S) URL" unless valid_url?(url)
      if rules[:check_tracking] && !has_tracking_source?(url)
        warnings << "#{display}: url is missing utm_source=testingconferences"
      end
    end

    if event.key?('video_playlist') && !valid_url?(event['video_playlist'])
      errors << "#{display}: video_playlist is not a valid HTTP(S) URL"
    end

    if event.key?('video_url') && !valid_url?(event['video_url'])
      warnings << "#{display}: video_url is not a valid HTTP(S) URL"
    end

    if relative_path == '_data/closed.yml'
      first_date = parse_event_date(event['first_date'], :start)
      last_date = parse_event_date(event['last_date'], :end)
      warnings << "#{display}: could not parse first_date" if event['first_date'] && first_date.nil?
      warnings << "#{display}: could not parse last_date" if event['last_date'] && last_date.nil?
      if first_date && last_date && first_date > last_date
        errors << "#{display}: first_date is after last_date"
      end
    elsif event['dates']
      order_date = parse_event_date(event['dates'], :start)
      warnings << "#{display}: could not parse dates for ordering" if order_date.nil?

      if rules[:order] && order_date && previous_date
        if rules[:order] == :ascending && order_date < previous_date
          warnings << "#{display}: appears out of chronological order"
        elsif rules[:order] == :descending && order_date > previous_date
          warnings << "#{display}: appears out of reverse chronological order"
        end
      end

      previous_date = order_date if order_date
    end
  end
rescue Psych::Exception => e
  errors << "#{relative_path}: YAML parse error: #{e.message}"
rescue Errno::ENOENT
  errors << "#{relative_path}: file not found"
end

seen_names.each do |name, paths|
  unique_paths = paths.uniq
  next if unique_paths.length == 1

  warnings << "#{name}: appears in multiple data files: #{unique_paths.join(', ')}"
end

warnings.each { |warning| warn "WARNING: #{warning}" }
errors.each { |error| warn "ERROR: #{error}" }

if errors.empty?
  puts "Conference data validation passed with #{warnings.length} warning(s)."
  exit 0
else
  warn "Conference data validation failed with #{errors.length} error(s) and #{warnings.length} warning(s)."
  exit 1
end
