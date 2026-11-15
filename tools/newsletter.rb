#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'cgi'
require 'optparse'
require 'tempfile'
require 'tmpdir'
require 'uri'
require 'yaml'

module Newsletter
  class InputError < StandardError; end

  ROOT = File.expand_path('..', __dir__)
  DEFAULT_DATA_FILE = File.join(ROOT, '_data', 'current.yml')

  MONTH_PATTERN = '(?:January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)'

  DISCOUNT_PATTERN = /\b(?:early|super\s+early|blind)[ -]?bird\b|\bblind\s+(?:tickets?|registration|pricing)\b|\bdiscounts?\b|\bsavings?\b|\breduced\s+pric(?:e|ing)\b/i
  CFP_PATTERN = /\b(?:CFP|call\s+for\s+(?:proposals|papers|speakers))\b/i
  ACTIVE_DISCOUNT_PATTERN = /\bopen\b|\bon\s+sale\b|\bavailable\b|\buntil\b|\bsave\b|\bsavings?\b|\d+%\s+off\b/i
  INACTIVE_PATTERN = /\b(?:closed|ended|expired|sold\s+out)\b/i
  NEGATED_ACTIVE_PATTERN = /\bnot\s+(?:yet\s+|currently\s+)?(?:open|available|on\s+sale)\b|\b(?:isn['’]t|aren['’]t)\s+(?:open|available|on\s+sale)\b/i

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

    def location
      source['location'].to_s
    end

    def dates
      source['dates'].to_s
    end

    def url
      source['url'].to_s
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
    crosses_year = start_month == 12 && end_month == 1
    return if start_month > end_month && !crosses_year

    start_year = crosses_year ? end_year - 1 : end_year
    start_date = Date.new(start_year, start_month, start_day)
    end_date = Date.new(end_year, end_month, end_day)
    return if end_date < start_date

    DateRange.new(start_date: start_date, end_date: end_date)
  rescue ArgumentError
    nil
  end

  def load_catalog(path)
    raw_events = YAML.safe_load(File.read(path), permitted_classes: [Date])
    raise InputError, "Expected an array in #{path}" unless raw_events.is_a?(Array)

    events = []
    unparseable = []

    raw_events.each_with_index do |source, index|
      validate_source!(source, index)
      range = parse_date_range(source['dates'])
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

    months.to_h do |month|
      month_events = events.select do |event|
        event.start_date.year == month.year && event.start_date.month == month.month
      end
      [month, month_events.sort_by { |event| [event.start_date, event.name.downcase, event.name] }]
    end
  end

  def render(catalog, target_month)
    groups = group_for_window(catalog.events, target_month)
    discounts = upcoming_discounts(catalog.events, target_month)
    cfps = open_cfps(catalog.events, target_month)
    final_month = target_month >> 2
    event_count = groups.values.sum(&:length)

    lines = [
      "# Software Testing Conferences Newsletter — #{month_label(target_month)}–#{month_label(final_month)}",
      '',
      "**Suggested subject:** #{event_count} #{pluralize(event_count, 'software testing conference')} from #{month_label(target_month)} through #{month_label(final_month)}",
      "**Suggested preheader:** #{discounts.length} #{pluralize(discounts.length, 'upcoming discount')} and #{cfps.length} #{pluralize(cfps.length, 'open CFP')}, plus a three-month conference calendar.",
      '',
      '<!-- EDITOR: Replace the introduction placeholder before sending. -->',
      '## Introduction',
      '',
      '[Write the introduction before sending.]',
      '',
      '<!-- EDITOR: Add approved sponsor copy or remove this section before sending. -->',
      '## Sponsor',
      '',
      '[Add sponsor copy or remove this section before sending.]',
      ''
    ]

    groups.each do |month, events|
      lines << "## #{month_label(month)}"
      lines << ''
      if events.empty?
        lines << "No conferences or workshops are currently listed for #{month_label(month)}."
        lines << ''
      else
        events.each { |event| lines.concat(event_lines(event)) }
      end
    end

    lines.concat(collection_lines('Upcoming discounts', discounts, 'No upcoming discounts are currently listed.'))
    lines.concat(collection_lines('Open CFPs', cfps, 'No open CFPs are currently listed.'))
    lines.concat([
      '<!-- EDITOR: Add announcements or remove this section before sending. -->',
      '## Announcements',
      '',
      '[Add announcements or remove this section before sending.]',
      '',
      '<!-- EDITOR: Replace the final-notes placeholder before sending. -->',
      '## Final notes',
      '',
      '[Add final notes before sending.]',
      '',
      'View the latest conference information at [TestingConferences.org](https://testingconferences.org/).',
      '',
      'Know of an event we missed? [Contribute to the community-maintained list](https://github.com/TestingConferences/testingconferences.github.io).',
      '',
      '## Review before sending',
      '',
      '- [ ] Replace or remove every editorial placeholder.',
      '- [ ] Verify conference details, discount availability, CFP status, and deadlines against official sources.',
      '- [ ] Check every link and review the final email on desktop, mobile, and plain text.'
    ])

    if catalog.unparseable.empty?
      lines << '- [ ] Confirm there are no newly ambiguous or unparseable conference dates.'
    else
      lines << '- [ ] Resolve or intentionally omit these ambiguous or unparseable conference dates:'
      catalog.unparseable.sort_by { |event| event.name.downcase }.each do |event|
        date_description = event.dates.empty? ? 'missing date' : "`#{escape_markdown(event.dates)}`"
        lines << "  - #{escape_markdown(event.name)} — #{date_description}"
      end
    end

    "#{lines.join("\n")}\n"
  end

  def default_output_path(target_month)
    File.join(ROOT, '_drafts', "#{target_month.strftime('%Y-%m')}-newsletter.md")
  end

  def run(argv, data_file: DEFAULT_DATA_FILE, stdout: $stdout, stderr: $stderr)
    options = parse_options(argv)
    raise InputError, 'Missing required option: --month YYYY-MM' if options[:month].to_s.empty?

    target_month = parse_target_month(options[:month])
    catalog = load_catalog(data_file)
    output = options[:output] || default_output_path(target_month)
    write_draft(output, render(catalog, target_month))
    stdout.puts "Newsletter draft written to #{output}"
    0
  rescue InputError, OptionParser::ParseError => e
    stderr.puts e.message
    1
  end

  def upcoming_discounts(events, target_month)
    upcoming_events(events, target_month).select do |event|
      active_discount?(plain_text(event.status))
    end
  end

  def open_cfps(events, target_month)
    upcoming_events(events, target_month).select do |event|
      status_clauses(plain_text(event.status)).any? { |clause| open_cfp_clause?(clause) }
    end
  end

  def status_markdown(value)
    text = remove_unsafe_elements(value.to_s)
    links = []

    text = text.gsub(%r{<a\b[^>]*\bhref=(['"])(.*?)\1[^>]*>(.*?)</a>}mi) do
      href = CGI.unescapeHTML(Regexp.last_match(2).to_s)
      label = escape_markdown(plain_text(Regexp.last_match(3)))
      replacement = markdown_link(label, href)
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
    text = CGI.escapeHTML(CGI.unescapeHTML(value.to_s))
    text.gsub(/([\\\[\]*#_`])/) { |character| "\\#{character}" }
  end

  def markdown_link(label, url)
    return label unless http_url?(url)

    destination = url.gsub('<', '%3C').gsub('>', '%3E')
    "[#{label}](<#{destination}>)"
  end
  private_class_method :markdown_link

  def validate_source!(source, index)
    raise InputError, "Conference data entry #{index + 1} must be a mapping" unless source.is_a?(Hash)

    %w[name location url].each do |field|
      next unless source[field].to_s.strip.empty?

      raise InputError, "Conference data entry #{index + 1} is missing #{field}"
    end
    return if http_url?(source['url'].to_s)

    raise InputError, "Conference data entry #{index + 1} has an invalid URL"
  end
  private_class_method :validate_source!

  def parse_options(argv)
    options = {}
    arguments = argv.dup
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: ruby tools/newsletter.rb --month YYYY-MM [--output PATH]'
      opts.on('--month YYYY-MM', 'First month in the three-month conference window') { |value| options[:month] = value }
      opts.on('--output PATH', 'Write the Markdown draft to PATH') { |value| options[:output] = value }
    end
    parser.parse!(arguments)
    raise OptionParser::InvalidArgument, "Unexpected arguments: #{arguments.join(' ')}" unless arguments.empty?

    options
  end
  private_class_method :parse_options

  def write_draft(path, content)
    destination = resolve_output_path(path)
    directory = File.dirname(destination)
    temporary = Tempfile.new(['newsletter', '.tmp'], directory)
    temporary.binmode
    temporary.write(content)
    temporary.flush
    temporary.fsync
    temporary.close
    File.rename(temporary.path, destination)
  rescue SystemCallError => e
    raise InputError, "Could not write newsletter draft: #{e.message}"
  ensure
    temporary&.close!
  end
  private_class_method :write_draft

  def resolve_output_path(path)
    expanded = File.expand_path(path)
    directory = File.realpath(File.dirname(expanded))
    destination = File.join(directory, File.basename(expanded))
    roots = allowed_output_roots

    unless roots.any? { |root| destination.start_with?("#{root}#{File::SEPARATOR}") }
      raise InputError, "Output path must be inside #{roots.join(' or ')}"
    end

    validate_output_owner!(destination, directory)
    destination
  rescue Errno::ENOENT
    raise InputError, "Output directory does not exist: #{File.dirname(expanded)}"
  end
  private_class_method :resolve_output_path

  def allowed_output_roots
    [
      File.realpath(File.join(ROOT, '_drafts')),
      File.realpath(Dir.tmpdir),
      File.realpath('/tmp')
    ].uniq
  end
  private_class_method :allowed_output_roots

  def validate_output_owner!(destination, directory)
    if File.exist?(destination) || File.symlink?(destination)
      file_stat = File.lstat(destination)
      raise InputError, "Output path must not be a symlink: #{destination}" if file_stat.symlink?
      raise InputError, "Output path must be a regular file: #{destination}" unless file_stat.file?
      raise InputError, "Output file is not owned by the current user: #{destination}" unless file_stat.uid == Process.uid
    end

    directory_stat = File.stat(directory)
    return if directory_stat.uid == Process.uid
    temporary_roots = [File.realpath(Dir.tmpdir), File.realpath('/tmp')].uniq
    return if temporary_roots.include?(directory) && directory_stat.world_writable? && directory_stat.sticky?

    raise InputError, "Output directory is not owned by the current user: #{directory}"
  end
  private_class_method :validate_output_owner!

  def event_lines(event)
    name = escape_markdown(event.name)
    heading = "### #{markdown_link(name, event.url)}"
    lines = [
      heading,
      '',
      "**Location:** #{escape_markdown(event.location)}",
      "**Dates:** #{escape_markdown(event.dates)}"
    ]
    status = status_markdown(event.status)
    lines << "**Status:** #{status}" unless status.empty?
    lines << ''
    lines
  end
  private_class_method :event_lines

  def collection_lines(heading, events, empty_message)
    lines = ["## #{heading}", '']
    if events.empty?
      lines.concat([empty_message, ''])
    else
      events.each { |event| lines.concat(event_lines(event)) }
    end
    lines
  end
  private_class_method :collection_lines

  def month_label(month)
    month.strftime('%B %Y')
  end
  private_class_method :month_label

  def pluralize(count, singular)
    count == 1 ? singular : "#{singular}s"
  end
  private_class_method :pluralize

  def upcoming_events(events, target_month)
    events.select { |event| event.end_date >= target_month }
          .sort_by { |event| [event.start_date, event.name.downcase, event.name] }
  end
  private_class_method :upcoming_events

  def active_discount?(status)
    status_clauses(status).any? do |clause|
      next false unless clause.match?(DISCOUNT_PATTERN)
      next false if inactive_clause?(clause)

      clause.match?(ACTIVE_DISCOUNT_PATTERN) || clause.match?(/\bdiscounts?\b/i)
    end
  end
  private_class_method :active_discount?

  def open_cfp_clause?(clause)
    return false unless clause.match?(CFP_PATTERN)
    return false if inactive_clause?(clause)

    subject = CFP_PATTERN.source
    clause.match?(/(?:#{subject})(?:\s+submissions?)?\s+(?:(?:is|are|remains?|now|currently)\s+){0,3}open\b/i) ||
      clause.match?(/\bopen\s+(?:#{subject})/i)
  end
  private_class_method :open_cfp_clause?

  def inactive_clause?(clause)
    clause.match?(INACTIVE_PATTERN) || clause.match?(NEGATED_ACTIVE_PATTERN)
  end
  private_class_method :inactive_clause?

  def status_clauses(status)
    status.split(/\s*(?:\||;|\.(?=\s|\z))\s*/).reject(&:empty?)
  end
  private_class_method :status_clauses

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

exit Newsletter.run(ARGV) if $PROGRAM_NAME == __FILE__
