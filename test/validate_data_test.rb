#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Regression tests for tools/validate_data.rb.
#
# These tests run the validator as a subprocess against fixture data
# directories under test/fixtures/*/_data, so they exercise the exact same
# code path as CI and contributors (`ruby tools/validate_data.rb`) without
# ever touching the real _data/ files.
#
# Run with: ruby test/validate_data_test.rb

require 'minitest/autorun'
require 'open3'

ROOT = File.expand_path('..', __dir__)
VALIDATOR = File.join(ROOT, 'tools', 'validate_data.rb')

def run_validator(fixture_name)
  fixture_root = File.join(ROOT, 'test', 'fixtures', fixture_name)
  env = { 'VALIDATE_DATA_ROOT' => fixture_root }
  stdout, stderr, status = Open3.capture3(env, 'ruby', VALIDATOR)
  [stdout, stderr, status]
end

class ValidateDataTest < Minitest::Test
  def test_valid_fixtures_pass_with_no_warnings_or_errors
    stdout, stderr, status = run_validator('valid')

    assert status.success?, "expected success, got stderr:\n#{stderr}"
    assert_includes stdout, 'passed with 0 warning(s)'
    assert_empty stderr
  end

  def test_missing_required_field_is_an_error
    _stdout, stderr, status = run_validator('errors')

    refute status.success?
    assert_match(/missing required field `name`/, stderr)
  end

  def test_invalid_url_is_an_error
    _stdout, stderr, status = run_validator('errors')

    assert_match(/url is not a valid HTTP\(S\) URL/, stderr)
  end

  def test_twitter_handle_with_at_symbol_is_an_error
    _stdout, stderr, status = run_validator('errors')

    assert_match(/twitter value should not include @/, stderr)
  end

  def test_unknown_field_in_strict_file_is_an_error
    _stdout, stderr, status = run_validator('errors')

    assert_match(/unknown fields: organizer/, stderr)
  end

  def test_first_date_after_last_date_is_an_error
    _stdout, stderr, status = run_validator('errors')

    assert_match(/first_date is after last_date/, stderr)
  end

  def test_missing_tracking_source_is_a_warning_not_an_error
    _stdout, stderr, status = run_validator('warnings')

    assert_match(/WARNING:.*missing utm_source=testingconferences/, stderr)
    refute_match(/ERROR:.*missing utm_source=testingconferences/, stderr)
  end

  def test_out_of_order_dates_is_a_warning
    _stdout, stderr, status = run_validator('warnings')

    assert_match(/WARNING:.*appears out of chronological order/, stderr)
  end

  def test_duplicate_name_in_same_file_is_a_warning
    _stdout, stderr, status = run_validator('warnings')

    assert_match(/WARNING:.*duplicate name in _data\/current\.yml/, stderr)
  end

  def test_unparsable_date_is_a_warning
    _stdout, stderr, status = run_validator('warnings')

    assert_match(/WARNING:.*could not parse dates for ordering/, stderr)
  end

  def test_warnings_fixture_still_exits_success
    _stdout, _stderr, status = run_validator('warnings')

    assert status.success?, 'warnings alone should not fail validation'
  end

  def test_single_day_date_parses_without_warning
    _stdout, stderr, _status = run_validator('dates')

    refute_match(/Single Day Conference.*could not parse/, stderr)
  end

  def test_same_month_date_range_parses_without_warning
    _stdout, stderr, _status = run_validator('dates')

    refute_match(/Same Month Range Conference.*could not parse/, stderr)
  end

  def test_cross_month_date_range_parses_without_warning
    _stdout, stderr, _status = run_validator('dates')

    refute_match(/Cross Month Range Conference.*could not parse/, stderr)
  end

  def test_reversed_day_month_range_parses_without_warning
    _stdout, stderr, _status = run_validator('dates')

    refute_match(/Reversed Day Month Range Conference.*could not parse/, stderr)
  end

  def test_abbreviated_month_parses_without_warning
    _stdout, stderr, _status = run_validator('dates')

    refute_match(/Abbreviated Month Conference.*could not parse/, stderr)
  end

  def test_closed_yml_date_range_parses
    _stdout, stderr, _status = run_validator('dates')

    refute_match(/Closed Date Range Conference.*could not parse/, stderr)
  end
end
