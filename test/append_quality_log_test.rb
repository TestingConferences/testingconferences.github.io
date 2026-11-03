#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

ROOT = File.expand_path('..', __dir__)
APPENDER = File.join(ROOT, 'tools', 'append_quality_log.rb')

class AppendQualityLogTest < Minitest::Test
  def test_appends_new_entry_to_existing_log
    Dir.mktmpdir do |dir|
      output = File.join(dir, 'quality_log.yml')
      File.write(output, [{ 'version' => 'v1', 'broken_links' => 0 }].to_yaml)

      _stdout, stderr, status = Open3.capture3(
        'ruby', APPENDER,
        '--version', 'v2',
        '--broken-links', '3',
        '--commit-sha', 'abc123',
        '--workflow-run-url', 'https://example.com/run/1',
        '--release-date', '2026-09-07T00:00:00Z',
        '--output', output
      )

      assert status.success?, "expected success, got stderr:\n#{stderr}"

      log = YAML.safe_load_file(output)
      assert_equal 2, log.length
      assert_equal 'v2', log.last['version']
      assert_equal 3, log.last['broken_links']
      assert_equal 'abc123', log.last['commit_sha']
      assert_equal 'https://example.com/run/1', log.last['workflow_run_url']
      assert_equal(
        { 'performance' => nil, 'accessibility' => nil, 'seo' => nil },
        log.last['lighthouse']
      )
    end
  end

  def test_rejects_negative_broken_link_count
    _stdout, stderr, status = Open3.capture3(
      'ruby', APPENDER,
      '--version', 'v2',
      '--broken-links', '-1'
    )

    refute status.success?
    assert_match(/--broken-links must be >= 0/, stderr)
  end

  def test_rejects_non_array_yaml_log
    Dir.mktmpdir do |dir|
      output = File.join(dir, 'quality_log.yml')
      File.write(output, { 'version' => 'v1' }.to_yaml)

      _stdout, stderr, status = Open3.capture3(
        'ruby', APPENDER,
        '--version', 'v2',
        '--broken-links', '1',
        '--output', output
      )

      refute status.success?
      assert_match(/Expected .* to contain a YAML array/, stderr)
    end
  end

  def test_rejects_malformed_yaml_log
    Dir.mktmpdir do |dir|
      output = File.join(dir, 'quality_log.yml')
      File.write(output, "---\n- version: v1\n  broken_links: [\n")

      _stdout, stderr, status = Open3.capture3(
        'ruby', APPENDER,
        '--version', 'v2',
        '--broken-links', '1',
        '--output', output
      )

      refute status.success?
      assert_match(/Invalid YAML in .*quality_log\.yml/, stderr)
    end
  end

  def test_allows_duplicate_versions_by_appending_new_entry
    Dir.mktmpdir do |dir|
      output = File.join(dir, 'quality_log.yml')
      File.write(output, [{ 'version' => 'v2', 'broken_links' => 0 }].to_yaml)

      _stdout, stderr, status = Open3.capture3(
        'ruby', APPENDER,
        '--version', 'v2',
        '--broken-links', '4',
        '--output', output
      )

      assert status.success?, "expected success, got stderr:\n#{stderr}"
      versions = YAML.safe_load_file(output).map { |entry| entry['version'] }
      assert_equal ['v2', 'v2'], versions
    end
  end
end
