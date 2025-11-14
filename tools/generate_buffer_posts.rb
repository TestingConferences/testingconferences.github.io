#!/usr/bin/env ruby
# frozen_string_literal: true
require 'optparse'
require 'csv'
require_relative 'lib/generate_buffer_posts'

options = {
  input: File.expand_path('_data/current.yml', __dir__),
  output: File.expand_path('~/Downloads/Buffer_Import_Template_generated.csv')
}

OptionParser.new do |opts|
  opts.banner = "Usage: generate_buffer_posts.rb [options]"
  opts.on('-i', '--input FILE', "Input YAML file (default: #{options[:input]})") { |v| options[:input] = v }
  opts.on('-o', '--output FILE', "Output CSV file (default: #{options[:output]})") { |v| options[:output] = v }
  opts.on('-h', '--help', 'Prints this help') { puts opts; exit }
end.parse!

unless File.exist?(options[:input])
  STDERR.puts "Input file not found: ", options[:input]
  exit 1
end

yaml_string = File.read(options[:input])
rows = Tools::GenerateBufferPosts.rows_from_yaml_string(yaml_string)

CSV.open(File.expand_path(options[:output]), 'wb') do |csv|
  csv << ['Text', 'Image URL', 'Tags', 'Posting Time']
  rows.each do |r|
    csv << r
  end
end

puts "Wrote #{rows.size} rows to #{File.expand_path(options[:output])}"
