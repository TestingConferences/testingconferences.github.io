#!/usr/bin/env ruby
# tools/lighthouse_audit.rb
# Runs Lighthouse audits against the built site and records metrics.
#
# Usage:
#   ruby tools/lighthouse_audit.rb [--version VERSION] [--site-url URL]
#
# Environment variables:
#   GITHUB_ACTIONS - Set by GitHub Actions to indicate running in CI
#   GITHUB_SHA - Commit SHA (GitHub Actions)
#   GITHUB_RUN_ID - Workflow run ID (GitHub Actions)
#   GITHUB_SERVER_URL - GitHub server URL (GitHub Actions)
#   GITHUB_REPOSITORY - Repository name (GitHub Actions)

require 'json'
require 'date'
require 'yaml'
require 'optparse'

# Parse command-line arguments
options = {}
OptionParser.new do |opts|
  opts.on('--version VERSION', String, 'Version number to record') do |v|
    options[:version] = v
  end
  opts.on('--site-url URL', String, 'URL to audit (default: http://localhost:4000)') do |v|
    options[:site_url] = v
  end
end.parse!

# Default values
site_url = options[:site_url] || 'http://localhost:4000'
version = options[:version] || ENV['VERSION']
commit_sha = ENV['GITHUB_SHA'] || `git rev-parse HEAD`.strip
workflow_run_url = nil

# Validate required parameters
if version.nil? || version.empty?
  puts "ERROR: Version is required. Provide with --version or set VERSION environment variable"
  exit 1
end

# Build workflow run URL if in GitHub Actions
if ENV['GITHUB_ACTIONS'] && ENV['GITHUB_SERVER_URL'] && ENV['GITHUB_REPOSITORY'] && ENV['GITHUB_RUN_ID']
  workflow_run_url = "#{ENV['GITHUB_SERVER_URL']}/#{ENV['GITHUB_REPOSITORY']}/actions/runs/#{ENV['GITHUB_RUN_ID']}"
end

puts "Lighthouse Audit Script"
puts "======================"
puts "Site URL: #{site_url}"
puts "Version: #{version}"
puts "Commit SHA: #{commit_sha}"
puts "Workflow Run URL: #{workflow_run_url || 'N/A'}"
puts ""

# Check if Lighthouse is installed
lighthouse_path = `which lighthouse`.strip
if lighthouse_path.empty?
  puts "ERROR: Lighthouse CLI not found. Install with: npm install -g lighthouse"
  exit 1
end

puts "Using Lighthouse from: #{lighthouse_path}"

# Run Lighthouse audit
puts "Running Lighthouse audit against #{site_url}..."

# Create a temporary output file
output_file = "lighthouse-report-#{Time.now.to_i}.json"

# Run lighthouse with JSON output
# Flags explained:
# --format=json: Output results as JSON for programmatic parsing
# --output-path=#{output_file}: Save report to specified file
# --chrome-flags='--no-sandbox': Required for running Chrome in containerized CI environments
# --throttling-method=simulate: Use simulated throttling for consistent audit environments
# --quiet: Suppress CLI progress output to keep logs clean
cmd = "lighthouse #{site_url} --format=json --output-path=#{output_file} --chrome-flags='--no-sandbox' --throttling-method=simulate --quiet"
puts "Executing: #{cmd}"

success = system(cmd)

unless success
  puts "ERROR: Lighthouse execution failed"
  exit 1
end

unless File.exist?(output_file)
  puts "ERROR: Lighthouse report not generated"
  exit 1
end

# Parse the Lighthouse report
begin
  report = JSON.parse(File.read(output_file))
rescue JSON::ParserError => e
  puts "ERROR: Invalid JSON in Lighthouse report: #{e.message}"
  exit 1
end

# Extract scores (Lighthouse v6+ format)
categories = report.dig('categories') || {}
performance = (categories.dig('performance', 'score') || 0) * 100
accessibility = (categories.dig('accessibility', 'score') || 0) * 100
seo = (categories.dig('seo', 'score') || 0) * 100

# Round to nearest integer
performance = performance.round
accessibility = accessibility.round
seo = seo.round

puts ""
puts "Lighthouse Scores:"
puts "  Performance: #{performance}"
puts "  Accessibility: #{accessibility}"
puts "  SEO: #{seo}"
puts ""

# Clean up temporary report
File.delete(output_file)

# Load existing quality log
quality_log_path = File.join(__dir__, '..', '_data', 'quality_log.yml')
entries = []

if File.exist?(quality_log_path)
  begin
    # Use YAML.safe_load for security (prevents arbitrary code execution).
    # YAML.safe_load parses files with comments but discards them during parsing.
    # The re-serialized YAML (written below) includes fresh header comments.
    content = File.read(quality_log_path)
    parsed = YAML.safe_load(content) || []
    entries = parsed.is_a?(Array) ? parsed : []
  rescue YAML::ParseError => e
    puts "WARNING: Could not parse existing quality log: #{e.message}"
    puts "Starting with empty entries list"
    entries = []
  end
end

# Create new entry
new_entry = {
  'version' => version.to_s,
  'release_date' => Date.today.to_s,
  'commit_sha' => commit_sha,
  'performance' => performance,
  'accessibility' => accessibility,
  'seo' => seo
}

new_entry['workflow_run_url'] = workflow_run_url if workflow_run_url

# Append entry to log
entries << new_entry

# Write back to quality log
File.open(quality_log_path, 'w') do |f|
  # Write header comments
  f.write("# Quality Log - Lighthouse Audit Metrics\n")
  f.write("# Stores performance, accessibility, and SEO scores for each released version.\n")
  f.write("# Format: stable YAML with append-only entries, one per released version.\n")
  f.write("# Version field format: integer (e.g., 1631).\n")
  f.write("# Scores: 0-100 integer scale (100 is best).\n")
  f.write("#\n")
  f.write("# Structure:\n")
  f.write("# - version: <integer>\n")
  f.write("#   release_date: <YYYY-MM-DD>\n")
  f.write("#   commit_sha: <git commit hash>\n")
  f.write("#   performance: <0-100>\n")
  f.write("#   accessibility: <0-100>\n")
  f.write("#   seo: <0-100>\n")
  f.write("#   workflow_run_url: <GitHub Actions run URL>\n")
  f.write("#\n")
  f.write("# This file is updated automatically by the lighthouse-audit workflow.\n")
  f.write("# Do not edit manually; append entries only via the automated workflow.\n")
  f.write("\n")
  f.write(YAML.dump(entries))
end

puts "Quality log updated: #{quality_log_path}"
puts "Entry: #{new_entry.inspect}"
puts ""
puts "Lighthouse audit complete!"
