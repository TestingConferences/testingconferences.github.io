#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require_relative '../tools/newsletter'

class NewsletterTest < Minitest::Test
  FIXTURE = File.expand_path('fixtures/newsletter/current.yml', __dir__)

  def test_target_month_requires_exact_year_month_format
    error = assert_raises(Newsletter::InputError) do
      Newsletter.parse_target_month('2026-1')
    end

    assert_equal 'Month must use YYYY-MM format: 2026-1', error.message
  end

  def test_target_month_rejects_an_invalid_calendar_month
    error = assert_raises(Newsletter::InputError) do
      Newsletter.parse_target_month('2026-13')
    end

    assert_equal 'Month is not valid: 2026-13', error.message
  end

  def test_target_month_returns_the_first_day
    assert_equal Date.new(2026, 11, 1), Newsletter.parse_target_month('2026-11')
  end

  def test_parses_supported_event_date_formats
    cases = {
      'November 18, 2026' => [Date.new(2026, 11, 18), Date.new(2026, 11, 18)],
      'November 4-6, 2026' => [Date.new(2026, 11, 4), Date.new(2026, 11, 6)],
      'November 30 - December 2, 2026' => [Date.new(2026, 11, 30), Date.new(2026, 12, 2)],
      'March 4-5 March, 2027' => [Date.new(2027, 3, 4), Date.new(2027, 3, 5)],
      'Sept 8-9, 2027' => [Date.new(2027, 9, 8), Date.new(2027, 9, 9)]
    }

    cases.each do |source, expected|
      range = Newsletter.parse_date_range(source)

      refute_nil range, "expected #{source.inspect} to parse"
      assert_equal expected[0], range.start_date, source
      assert_equal expected[1], range.end_date, source
    end
  end

  def test_unparseable_or_ambiguous_dates_are_not_guessed
    assert_nil Newsletter.parse_date_range('2027 TBA')
    assert_nil Newsletter.parse_date_range('Sometime next spring')
    assert_nil Newsletter.parse_date_range(nil)
  end

  def test_catalog_keeps_unparseable_events_for_editorial_review
    catalog = Newsletter.load_catalog(FIXTURE)

    assert_equal 14, catalog.events.length
    assert_equal ['Date To Be Announced Conference'], catalog.unparseable.map(&:name)
  end

  def test_three_month_window_crosses_year_and_orders_events
    catalog = Newsletter.load_catalog(FIXTURE)
    target_month = Newsletter.parse_target_month('2026-11')

    groups = Newsletter.group_for_window(catalog.events, target_month)

    assert_equal [Date.new(2026, 11, 1), Date.new(2026, 12, 1), Date.new(2027, 1, 1)], groups.keys
    assert_equal [
      'Alpha November Conference',
      'Beta November Conference',
      'Cross-Month Conference'
    ], groups.fetch(Date.new(2026, 11, 1)).map(&:name)
    assert_equal ['December Conference'], groups.fetch(Date.new(2026, 12, 1)).map(&:name)
    assert_equal ['January Conference'], groups.fetch(Date.new(2027, 1, 1)).map(&:name)
  end

  def test_cross_month_event_is_grouped_under_its_start_month
    catalog = Newsletter.load_catalog(FIXTURE)
    groups = Newsletter.group_for_window(catalog.events, Date.new(2026, 12, 1))

    refute_includes groups.fetch(Date.new(2026, 12, 1)).map(&:name), 'Cross-Month Conference'
  end

  def test_converts_supported_status_html_to_safe_markdown
    source = <<~HTML.strip
      <a href="https://example.com/tickets?utm_source=testingconferences&amp;plan=early">Early Bird **Registration** &amp; Pricing</a> until December 1, 2026 | <strong>Save 20%</strong><script>alert(1)</script>
    HTML

    converted = Newsletter.status_markdown(source)

    assert_equal(
      '[Early Bird \*\*Registration\*\* & Pricing](https://example.com/tickets?utm_source=testingconferences&plan=early) until December 1, 2026 | Save 20%',
      converted
    )
    assert_equal 'Review details', Newsletter.status_markdown('<a href="javascript:alert(1)">Review details</a>')
  end

  def test_escapes_markdown_significant_source_text
    assert_equal(
      'QA \\[Lab\\] \\*Conference\\* \\#1',
      Newsletter.escape_markdown('QA [Lab] *Conference* #1')
    )
  end

  def test_selects_all_upcoming_active_discounts_outside_event_window
    catalog = Newsletter.load_catalog(FIXTURE)

    discounts = Newsletter.upcoming_discounts(catalog.events, Date.new(2026, 11, 1))

    assert_equal [
      'Early Bird Conference',
      'Blind Ticket Conference',
      'Blind Registration Conference'
    ], discounts.map(&:name)
  end

  def test_selects_all_upcoming_open_cfps_outside_event_window
    catalog = Newsletter.load_catalog(FIXTURE)

    cfps = Newsletter.open_cfps(catalog.events, Date.new(2026, 11, 1))

    assert_equal [
      'Open CFP Conference',
      'Open Call for Papers Conference'
    ], cfps.map(&:name)
  end

  def test_ordinary_registration_does_not_enter_global_status_lists
    catalog = Newsletter.load_catalog(FIXTURE)
    target_month = Date.new(2026, 11, 1)

    discount_names = Newsletter.upcoming_discounts(catalog.events, target_month).map(&:name)
    cfp_names = Newsletter.open_cfps(catalog.events, target_month).map(&:name)

    refute_includes discount_names, 'Registration Only Conference'
    refute_includes cfp_names, 'Registration Only Conference'
  end
end
