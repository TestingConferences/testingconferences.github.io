#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'cgi'
require 'uri'
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

    def status
      source['status'].to_s
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

  def upcoming_discounts(events, target_month)
    upcoming_events(events, target_month).select do |event|
      active_discount?(plain_text(event.status))
    end
  end

  def open_cfps(events, target_month)
    upcoming_events(events, target_month).select do |event|
      status = plain_text(event.status)
      cfp_status?(status) && status.match?(/\bopen\b/i)
    end
  end

  def status_markdown(value)
    text = remove_unsafe_elements(value.to_s)
    links = []

    text = text.gsub(%r{<a\b[^>]*\bhref=(['"])(.*?)\1[^>]*>(.*?)</a>}mi) do
      href = CGI.unescapeHTML(Regexp.last_match(2).to_s)
      label = escape_markdown(plain_text(Regexp.last_match(3)))
      replacement = http_url?(href) ? "[#{label}](#{href})" : label
      links << replacement
      "NEWSLETTERLINKTOKEN#{links.length - 1}END"
    end

    converted = escape_markdown(plain_text(text))
    links.each_with_index do |link, index|
      converted = converted.sub("NEWSLETTERLINKTOKEN#{index}END", link)
    end
    converted
  end

  def escape_markdown(value)
    value.to_s.gsub(/([\\\[\]*#_`])/) { |character| "\\#{character}" }
  end

  def upcoming_events(events, target_month)
    events.select { |event| event.end_date >= target_month }
          .sort_by { |event| [event.start_date, event.name.downcase, event.name] }
  end
  private_class_method :upcoming_events

  def active_discount?(status)
    discount = status.match?(/\b(?:early|super\s+early|blind)[ -]?bird\b|\bblind\s+(?:tickets?|registration|pricing)\b|\bdiscounts?\b|\bsavings?\b|\breduced\s+pric(?:e|ing)\b/i)
    active = status.match?(/\bopen\b|\bon\s+sale\b|\bavailable\b|\buntil\b|\bsave\b|\bsavings?\b|\d+%\s+off\b/i)
    inactive = status.match?(/\bclosed\b|\bended\b|\bexpired\b|\bsold\s+out\b/i)

    discount && (active || (!inactive && status.match?(/\bdiscounts?\b/i)))
  end
  private_class_method :active_discount?

  def cfp_status?(status)
    status.match?(/\bCFP\b|\bcall\s+for\s+(?:proposals|papers|speakers)\b/i)
  end
  private_class_method :cfp_status?

  def plain_text(value)
    CGI.unescapeHTML(remove_unsafe_elements(value.to_s).gsub(%r{<[^>]+>}m, ' '))
       .gsub(/\s+/, ' ')
       .strip
  end
  private_class_method :plain_text

  def remove_unsafe_elements(value)
    value.gsub(%r{<(script|style)\b[^>]*>.*?</\1>}mi, '')
  end
  private_class_method :remove_unsafe_elements

  def http_url?(value)
    uri = URI.parse(value)
    uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
  rescue URI::InvalidURIError
    false
  end
  private_class_method :http_url?

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
