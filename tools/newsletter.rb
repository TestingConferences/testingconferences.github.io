#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'yaml'

module Newsletter
  class InputError < StandardError; end

  MONTH_PATTERN = '(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)'

  MONTH_NAMES = {
    'jan' => 'January',
    'feb' => 'February',
    'mar' => 'March',
    'apr' => 'April',
    'may' => 'May',
    'jun' => 'June',
    'jul' => 'July',
    'aug' => 'August',
    'sep' => 'September',
    'sept' => 'September',
    'oct' => 'October',
    'nov' => 'November',
    'dec' => 'December'
  }.freeze

  DateRange = Struct.new(:start_date, :end_date, keyword_init: true)

  Event = Struct.new(:source, :start_date, :end_date, keyword_init: true) do
    def name
      source['name'].to_s
    end
  end

  Catalog = Struct.new(:events, :unparseable, keyword_init: true)

  module_function

  def parse_target_month(value)
    text = value.to_s
    raise InputError, "Month must use YYYY-MM format: #{text}" unless text.match?(/\A\d{4}-\d{2}\z/)

    Date.strptime("#{text}-01", '%Y-%m-%d')
  rescue ArgumentError
    raise InputError, "Month is not valid: #{text}"
  end

  def parse_date_range(value)
    return if value.nil?

    text = value.to_s.strip.gsub(/[–—]/, '-')
    components = date_components(text)
    return unless components

    start_month, start_day, end_month, end_day, end_year = components
    start_year = start_month > end_month ? end_year - 1 : end_year

    DateRange.new(
      start_date: Date.new(start_year, start_month, start_day),
      end_date: Date.new(end_year, end_month, end_day)
    )
  rescue ArgumentError
    nil
  end

  def load_catalog(path)
    raw_events = YAML.safe_load(File.read(path), permitted_classes: [Date])
    raise InputError, "Expected an array in #{path}" unless raw_events.is_a?(Array)

    events = []
    unparseable = []

    raw_events.each do |source|
      range = parse_date_range(source['dates']) if source.is_a?(Hash)
      event = Event.new(source: source, start_date: range&.start_date, end_date: range&.end_date)
      range ? events << event : unparseable << event
    end

    Catalog.new(events: events, unparseable: unparseable)
  rescue Errno::ENOENT
    raise InputError, "Conference data file not found: #{path}"
  rescue Psych::Exception => e
    raise InputError, "Conference data YAML is invalid: #{e.message}"
  end

  def group_for_window(events, target_month)
    months = 3.times.map { |offset| target_month >> offset }
    window_end = target_month >> 3
    selected = events.select do |event|
      event.start_date >= target_month && event.start_date < window_end
    end

    months.to_h do |month|
      month_events = selected.select do |event|
        event.start_date.year == month.year && event.start_date.month == month.month
      end
      [month, month_events.sort_by { |event| [event.start_date, event.name.downcase, event.name] }]
    end
  end

  def date_components(text)
    case text
    when /\A(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(#{MONTH_PATTERN})\s*(\d{1,2}),?\s*(\d{4})\z/i
      [month_number(Regexp.last_match(1)), Regexp.last_match(2).to_i,
       month_number(Regexp.last_match(3)), Regexp.last_match(4).to_i,
       Regexp.last_match(5).to_i]
    when /\A(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(\d{1,2}),?\s*(\d{4})\z/i
      month = month_number(Regexp.last_match(1))
      [month, Regexp.last_match(2).to_i, month, Regexp.last_match(3).to_i,
       Regexp.last_match(4).to_i]
    when /\A(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(\d{1,2})\s+(#{MONTH_PATTERN}),?\s*(\d{4})\z/i
      [month_number(Regexp.last_match(1)), Regexp.last_match(2).to_i,
       month_number(Regexp.last_match(4)), Regexp.last_match(3).to_i,
       Regexp.last_match(5).to_i]
    when /\A(#{MONTH_PATTERN})\s+(\d{1,2}),?\s*(\d{4})\z/i
      month = month_number(Regexp.last_match(1))
      [month, Regexp.last_match(2).to_i, month, Regexp.last_match(2).to_i,
       Regexp.last_match(3).to_i]
    end
  end
  private_class_method :date_components

  def month_number(name)
    normalized = MONTH_NAMES.fetch(name.downcase, name.capitalize)
    Date::MONTHNAMES.index(normalized)
  end
  private_class_method :month_number
end
