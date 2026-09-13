#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'yaml'
require 'time'

options = {
  output: '_data/quality_log.yml',
  release_date: Time.now.utc.iso8601
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby tools/append_quality_log.rb --version v123 --broken-links 0 [options]'

  opts.on('--version VERSION', 'Release version (for example: v123)') { |v| options[:version] = v }
  opts.on('--broken-links COUNT', Integer, 'Broken link count') { |v| options[:broken_links] = v }
  opts.on('--commit-sha SHA', 'Commit SHA for this snapshot') { |v| options[:commit_sha] = v }
  opts.on('--workflow-run-url URL', 'Workflow run URL') { |v| options[:workflow_run_url] = v }
  opts.on('--release-date DATE', 'Release date (ISO 8601)') { |v| options[:release_date] = v }
  opts.on('--output PATH', 'Output YAML path') { |v| options[:output] = v }
end.parse!

abort('Missing required --version') unless options[:version]
abort('Missing required --broken-links') unless options.key?(:broken_links)
abort('--broken-links must be >= 0') if options[:broken_links].negative?

log_entries =
  if File.exist?(options[:output])
    begin
      data = YAML.safe_load_file(options[:output], permitted_classes: [Time], aliases: false)
    rescue Psych::SyntaxError => e
      abort("Invalid YAML in #{options[:output]}: #{e.message}")
    end

    abort("Expected #{options[:output]} to contain a YAML array (or be empty)") unless data.nil? || data.is_a?(Array)
    data || []
  else
    []
  end

log_entries << {
  'version' => options[:version],
  'release_date' => options[:release_date],
  'commit_sha' => options[:commit_sha],
  'lighthouse' => {
    'performance' => nil,
    'accessibility' => nil,
    'seo' => nil
  },
  'broken_links' => options[:broken_links],
  'build_time_seconds' => nil,
  'workflow_run_url' => options[:workflow_run_url]
}

File.write(options[:output], log_entries.to_yaml)
puts "Appended quality log entry for #{options[:version]} with #{options[:broken_links]} broken link(s)."
