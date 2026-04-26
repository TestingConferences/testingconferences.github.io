#!/usr/bin/env ruby
# frozen_string_literal: true

require 'base64'
require 'date'
require 'json'
require 'net/http'
require 'optparse'
require 'uri'
require 'yaml'

DATA_FILE = File.expand_path('../_data/current.yml', __dir__)
ENV_FILE = File.expand_path('../.env', __dir__)
DEFAULT_LIMIT = 12
DEFAULT_DAYS_AHEAD = 60
DEFAULT_PLACEHOLDER = '{{TESTING_CONFERENCES_CONTENT}}'
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

def build_date(month_name, day, year)
  month_index = Date::MONTHNAMES.index(month_name)
  return nil unless month_index

  Date.new(year.to_i, month_index, day.to_i)
rescue ArgumentError
  nil
end

def parse_end_date(value)
  return nil if value.nil?

  s = value.to_s.strip.gsub(/[–—]/, '-')

  if (m = s.match(/(#{MONTH_PATTERN})\s+(\d{1,2})\s*-\s*(#{MONTH_PATTERN})\s*(\d{1,2}),?\s*(\d{4})$/i))
    return build_date(normalize_month(m[3]), m[4], m[5])
  end

  if (m = s.match(/(#{MONTH_PATTERN})\s+\d{1,2}\s*-\s*(\d{1,2}),?\s*(\d{4})$/i))
    return build_date(normalize_month(m[1]), m[2], m[3])
  end

  if (m = s.match(/(#{MONTH_PATTERN})\s+\d{1,2}\s*-\s*(\d{1,2})\s+(#{MONTH_PATTERN}),?\s*(\d{4})$/i))
    return build_date(normalize_month(m[3]), m[2], m[4])
  end

  if (m = s.match(/(#{MONTH_PATTERN})\s+(\d{1,2}),?\s*(\d{4})$/i))
    return build_date(normalize_month(m[1]), m[2], m[3])
  end

  Date.parse(s)
rescue ArgumentError
  nil
end

def strip_html(text)
  text.to_s.gsub(%r{<[^>]+>}, '').gsub(/\s+/, ' ').strip
end

def html_escape(text)
  text.to_s
      .gsub('&', '&amp;')
      .gsub('<', '&lt;')
      .gsub('>', '&gt;')
      .gsub('"', '&quot;')
      .gsub("'", '&#39;')
end

def unquote_env_value(value)
  return value[1..-2].gsub('\"', '"').gsub("\\'", "'") if value.start_with?('"') && value.end_with?('"')
  return value[1..-2].gsub("\\'", "'").gsub('\\"', '"') if value.start_with?("'") && value.end_with?("'")

  value
end

def load_dotenv(path)
  return unless File.exist?(path)

  File.foreach(path) do |line|
    stripped = line.strip
    next if stripped.empty? || stripped.start_with?('#')

    stripped = stripped.sub(/^export\s+/, '')
    key, value = stripped.split('=', 2)
    next if key.nil? || value.nil?

    key = key.strip
    value = unquote_env_value(value.strip)
    next if key.empty? || value.empty?
    next unless ENV[key].to_s.strip.empty?

    ENV[key] = value
  end
end

class MailchimpClient
  def initialize(api_key)
    @api_key = api_key
    dc = api_key.to_s.split('-').last
    raise ArgumentError, 'MAILCHIMP_API_KEY must end with data center suffix (for example: -us6)' if dc.nil? || dc.empty?

    @base_uri = URI("https://#{dc}.api.mailchimp.com/3.0")
  end

  def request(method, path, body: nil)
    uri = URI.join(@base_uri.to_s + '/', path.sub(%r{^/}, ''))
    req_class = case method.upcase
                when 'GET' then Net::HTTP::Get
                when 'POST' then Net::HTTP::Post
                when 'PATCH' then Net::HTTP::Patch
                when 'PUT' then Net::HTTP::Put
                else
                  raise ArgumentError, "Unsupported method: #{method}"
                end

    req = req_class.new(uri)
    req['Authorization'] = "Basic #{Base64.strict_encode64("anystring:#{@api_key}")}"
    req['Content-Type'] = 'application/json'
    req.body = JSON.generate(body) if body

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(req)

    parsed = response.body.to_s.empty? ? {} : JSON.parse(response.body)
    return parsed if response.code.to_i.between?(200, 299)

    detail = parsed.is_a?(Hash) ? parsed['detail'] : response.body
    raise "Mailchimp API error (#{response.code} #{response.message}) on #{method} #{path}: #{detail}"
  end
end

def build_events_html(events)
  items = events.map do |event|
    name = html_escape(event['name'])
    url = html_escape(event['url'])
    dates = html_escape(event['dates'])
    location = html_escape(event['location'])
    status = strip_html(event['status'])
    status_html = status.empty? ? '' : "<br><span style=\"color:#666;\">#{html_escape(status)}</span>"

    [
      '<li style="margin-bottom:14px;">',
      "<a href=\"#{url}\" target=\"_blank\" rel=\"noopener\"><strong>#{name}</strong></a>",
      "<br>#{dates}#{location.empty? ? '' : " - #{location}"}",
      status_html,
      '</li>'
    ].join
  end

  [
    '<h2 style="margin:0 0 12px;">Upcoming Software Testing Conferences</h2>',
    '<p style="margin:0 0 16px;">Curated from testingconferences.org.</p>',
    '<ul style="padding-left:20px; margin:0;">',
    items.join,
    '</ul>'
  ].join
end

def insert_newsletter_content(original_html, generated_html, placeholder)
  return generated_html if original_html.to_s.strip.empty?
  return original_html.sub(placeholder, generated_html) if original_html.include?(placeholder)

  if original_html.include?('</body>')
    return original_html.sub('</body>', "<hr style=\"border:none;border-top:1px solid #ddd;margin:24px 0;\">#{generated_html}</body>")
  end

  original_html + "\n#{generated_html}"
end

load_dotenv(ENV_FILE)

options = {
  limit: DEFAULT_LIMIT,
  days_ahead: DEFAULT_DAYS_AHEAD,
  placeholder: DEFAULT_PLACEHOLDER,
  dry_run: false,
  source_campaign_id: ENV['MAILCHIMP_SOURCE_CAMPAIGN_ID'],
  subject: nil,
  title_prefix: 'TestingConferences Newsletter'
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby tools/mailchimp_replicate_newsletter.rb [options]'
  opts.on('--source-campaign ID', 'Mailchimp campaign ID to replicate (or set MAILCHIMP_SOURCE_CAMPAIGN_ID)') { |v| options[:source_campaign_id] = v }
  opts.on('--limit N', Integer, "Max events to include (default: #{DEFAULT_LIMIT})") { |v| options[:limit] = v }
  opts.on('--days-ahead N', Integer, "Only include events ending within N days from today (default: #{DEFAULT_DAYS_AHEAD})") { |v| options[:days_ahead] = v }
  opts.on('--placeholder TEXT', "Placeholder in the source campaign HTML (default: #{DEFAULT_PLACEHOLDER})") { |v| options[:placeholder] = v }
  opts.on('--subject TEXT', 'Optional subject line override for the new draft') { |v| options[:subject] = v }
  opts.on('--title-prefix TEXT', 'Title prefix for the new draft') { |v| options[:title_prefix] = v }
  opts.on('--dry-run', 'Preview generated event HTML without Mailchimp API calls') { options[:dry_run] = true }
end.parse!

unless File.exist?(DATA_FILE)
  warn "Data file not found: #{DATA_FILE}"
  exit 1
end

raw_events = YAML.safe_load(File.read(DATA_FILE))
unless raw_events.is_a?(Array)
  warn "Expected an array in #{DATA_FILE}"
  exit 1
end

today = Date.today
cutoff = today + options[:days_ahead]
selected_events = raw_events.select { |event| (d = parse_end_date(event['dates'])) && d >= today && d <= cutoff }
                         .first(options[:limit])

if selected_events.empty?
  warn "No upcoming events found between #{today} and #{cutoff}."
  exit 1
end

generated_html = build_events_html(selected_events)

if options[:dry_run]
  puts generated_html
  puts "\nIncluded #{selected_events.size} events."
  exit 0
end

api_key = ENV['MAILCHIMP_API_KEY'].to_s.strip
if api_key.empty?
  warn 'MAILCHIMP_API_KEY is required unless using --dry-run.'
  exit 1
end

source_id = options[:source_campaign_id].to_s.strip
if source_id.empty?
  warn 'MAILCHIMP_SOURCE_CAMPAIGN_ID is required (or pass --source-campaign).'
  exit 1
end

client = MailchimpClient.new(api_key)
replicated = client.request('POST', "/campaigns/#{source_id}/actions/replicate")
new_campaign_id = replicated['id']

content = client.request('GET', "/campaigns/#{new_campaign_id}/content")
base_html = content['html'] || ''
updated_html = insert_newsletter_content(base_html, generated_html, options[:placeholder])
client.request('PUT', "/campaigns/#{new_campaign_id}/content", body: { html: updated_html })

title = "#{options[:title_prefix]} #{today}"
settings_payload = { title: title }
settings_payload[:subject_line] = options[:subject] if options[:subject]
client.request('PATCH', "/campaigns/#{new_campaign_id}", body: { settings: settings_payload })

puts "Created draft campaign: #{new_campaign_id}"
puts "Included #{selected_events.size} events (#{today} to #{cutoff})."
puts "Content insertion mode: #{base_html.include?(options[:placeholder]) ? 'placeholder replaced' : 'appended'}"
