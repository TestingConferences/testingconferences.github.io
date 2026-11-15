#!/usr/bin/env ruby
# frozen_string_literal: true

require 'date'
require 'minitest/autorun'
require 'stringio'
require 'tmpdir'
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

  def test_rejects_reversed_ranges_and_only_rolls_over_at_a_clear_year_boundary
    assert_nil Newsletter.parse_date_range('November 19-16, 2026')
    assert_nil Newsletter.parse_date_range('November 30 - October 2, 2026')
    assert_nil Newsletter.parse_date_range('December 30 - February 2, 2027')

    range = Newsletter.parse_date_range('December 30 - January 2, 2027')

    refute_nil range
    assert_equal Date.new(2026, 12, 30), range.start_date
    assert_equal Date.new(2027, 1, 2), range.end_date
  end

  def test_catalog_keeps_unparseable_events_for_editorial_review
    catalog = Newsletter.load_catalog(FIXTURE)

    assert_equal 14, catalog.events.length
    assert_equal [
      'Date To Be Announced Conference',
      'Missing Date Conference'
    ], catalog.unparseable.map(&:name)
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
      '[Early Bird \*\*Registration\*\* &amp; Pricing](<https://example.com/tickets?utm_source=testingconferences&plan=early>) until December 1, 2026 | Save 20%',
      converted
    )
    assert_equal 'Review details', Newsletter.status_markdown('<a href="javascript:alert(1)">Review details</a>')
  end

  def test_markdown_links_preserve_parentheses_in_destinations
    status = Newsletter.status_markdown(
      '<a href="https://example.com/tickets)preview">Registration is Open</a>'
    )
    event = event_with(
      name: 'Parenthesized URL Conference',
      url: 'https://example.com/event)preview'
    )
    draft = Newsletter.render(Newsletter::Catalog.new(events: [event], unparseable: []), Date.new(2026, 11, 1))

    assert_equal '[Registration is Open](<https://example.com/tickets)preview>)', status
    assert_includes draft, '### [Parenthesized URL Conference](<https://example.com/event)preview>)'
  end

  def test_escapes_markdown_significant_source_text
    assert_equal(
      'QA &lt;script&gt;alert(1)&lt;/script&gt; &amp; \\[Lab\\] \\*Conference\\* \\#1',
      Newsletter.escape_markdown('QA <script>alert(1)</script> & [Lab] *Conference* #1')
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

  def test_discount_state_is_evaluated_in_the_discount_clause
    events = [
      event_with(
        name: 'Closed Early Bird',
        status: 'Early Bird Registration is Closed | Regular Registration is Open'
      ),
      event_with(
        name: 'Closed Inline Early Bird',
        status: 'Early Bird Registration is Closed, regular registration is open'
      ),
      event_with(
        name: 'Closed Reverse Early Bird',
        status: 'Regular Registration is Open, Early Bird Registration is Closed'
      ),
      event_with(
        name: 'Open Early Bird',
        status: 'Early Bird Registration is Open | CFP is Closed'
      ),
      event_with(
        name: 'Open Early Bird First',
        status: 'Early Bird Registration is Open, CFP is Closed'
      ),
      event_with(
        name: 'Open Early Bird Last',
        status: 'CFP is Closed, Early Bird Registration is Open'
      ),
      event_with(
        name: 'Open Early Bird After Conjunction',
        status: 'Early bird registration is open, and the CFP is closed'
      ),
      event_with(
        name: 'Dated Early Bird',
        status: 'Early Bird Registration until December 1, 2026'
      )
    ]

    discounts = Newsletter.upcoming_discounts(events, Date.new(2026, 11, 1))

    assert_equal [
      'Dated Early Bird',
      'Open Early Bird',
      'Open Early Bird After Conjunction',
      'Open Early Bird First',
      'Open Early Bird Last'
    ], discounts.map(&:name)
  end

  def test_comma_only_splits_when_it_introduces_another_status_subject
    events = [
      event_with(name: 'Sold Out Discount', status: 'Early bird discount, sold out'),
      event_with(
        name: 'Available Registration',
        status: 'Early bird registration, available through January 1'
      )
    ]

    discounts = Newsletter.upcoming_discounts(events, Date.new(2026, 11, 1))

    assert_equal ['Available Registration'], discounts.map(&:name)
  end

  def test_selects_all_upcoming_open_cfps_outside_event_window
    catalog = Newsletter.load_catalog(FIXTURE)

    cfps = Newsletter.open_cfps(catalog.events, Date.new(2026, 11, 1))

    assert_equal [
      'Open CFP Conference',
      'Open Call for Papers Conference'
    ], cfps.map(&:name)
  end

  def test_open_cfp_requires_an_affirmative_state_in_the_cfp_clause
    events = [
      event_with(name: 'Closed CFP', status: 'CFP is Closed | Registration is Open'),
      event_with(name: 'Closed Reverse CFP', status: 'Registration is Open, CFP is Closed'),
      event_with(name: 'Future CFP', status: 'CFP is not open yet'),
      event_with(name: 'Open CFP', status: 'CFP is Open | Registration is Closed'),
      event_with(name: 'Open CFP First', status: 'CFP is now open, registration is closed'),
      event_with(name: 'Open CFP Last', status: 'Registration is closed, CFP is now open'),
      event_with(name: 'Open CFP Before Conjunction', status: 'CFP is open, but registration is closed'),
      event_with(name: 'Open Papers', status: 'Registration is Open | Call for Papers is Open'),
      event_with(name: 'Colon CFP', status: 'CFP: Open'),
      event_with(name: 'Historic Open CFP', status: 'Call for proposals has been open since January 1')
    ]

    cfps = Newsletter.open_cfps(events, Date.new(2026, 11, 1))

    assert_equal [
      'Colon CFP',
      'Historic Open CFP',
      'Open CFP',
      'Open CFP Before Conjunction',
      'Open CFP First',
      'Open CFP Last',
      'Open Papers'
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

  def test_rendered_draft_follows_the_editorial_section_order
    catalog = Newsletter.load_catalog(FIXTURE)
    draft = Newsletter.render(catalog, Date.new(2026, 11, 1))

    headings = [
      '## Introduction',
      '## Sponsor',
      '## November 2026',
      '## December 2026',
      '## January 2027',
      '## Upcoming discounts',
      '## Open CFPs',
      '## Announcements',
      '## Final notes',
      '## Review before sending'
    ]

    positions = headings.map { |heading| draft.index(heading) }
    refute_includes positions, nil
    assert_equal positions.sort, positions
    assert_includes draft, '**Status:** Registration is Open and Free'
    assert_includes draft, '[Early Bird Registration is Open](<https://example.com/tickets?utm_source=testingconferences&plan=early>) until December 1, 2026'
    assert_includes draft, '### [Open CFP Conference](<https://example.com/open-cfp?utm_source=testingconferences>)'
    refute_includes draft, '### [Registration Only Conference]'
  end

  def test_rendered_draft_contains_visible_editorial_placeholders
    draft = Newsletter.render(Newsletter.load_catalog(FIXTURE), Date.new(2026, 11, 1))

    assert_includes draft, '[Write the introduction before sending.]'
    assert_includes draft, '[Add sponsor copy or remove this section before sending.]'
    assert_includes draft, '[Add announcements or remove this section before sending.]'
    assert_includes draft, '[Add final notes before sending.]'
    assert_equal 4, draft.scan('<!-- EDITOR:').length
  end

  def test_rendered_draft_surfaces_unparseable_dates_for_review
    draft = Newsletter.render(Newsletter.load_catalog(FIXTURE), Date.new(2026, 11, 1))

    assert_includes draft, 'Date To Be Announced Conference — `2027 TBA`'
    assert_includes draft, 'Missing Date Conference — missing date'
  end

  def test_rendered_event_omits_missing_optional_status
    draft = Newsletter.render(Newsletter.load_catalog(FIXTURE), Date.new(2026, 11, 1))
    january_section = draft[/## January 2027\n(.*?)## Upcoming discounts/m, 1]

    assert_includes january_section, 'January Conference'
    refute_includes january_section, '**Status:**'
  end

  def test_empty_window_still_renders_three_months_and_placeholders
    draft = Newsletter.render(Newsletter.load_catalog(FIXTURE), Date.new(2028, 1, 1))

    assert_includes draft, '## January 2028'
    assert_includes draft, '## February 2028'
    assert_includes draft, '## March 2028'
    assert_equal 3, draft.scan('No conferences or workshops are currently listed for').length
    assert_includes draft, 'No upcoming discounts are currently listed.'
    assert_includes draft, 'No open CFPs are currently listed.'
  end

  def test_rendering_is_byte_deterministic
    catalog = Newsletter.load_catalog(FIXTURE)
    target_month = Date.new(2026, 11, 1)

    assert_equal Newsletter.render(catalog, target_month), Newsletter.render(catalog, target_month)
  end

  def test_default_output_path_uses_the_target_month
    assert_equal(
      File.expand_path('../_drafts/2026-11-newsletter.md', __dir__),
      Newsletter.default_output_path(Date.new(2026, 11, 1))
    )
  end

  def test_cli_writes_an_explicit_output_and_regenerates_identically
    Dir.mktmpdir do |directory|
      output = File.join(directory, 'newsletter.md')
      stdout = StringIO.new
      stderr = StringIO.new

      first_status = Newsletter.run(
        ['--month', '2026-11', '--output', output],
        data_file: FIXTURE,
        stdout: stdout,
        stderr: stderr
      )
      first_content = File.binread(output)
      second_status = Newsletter.run(
        ['--month', '2026-11', '--output', output],
        data_file: FIXTURE,
        stdout: StringIO.new,
        stderr: StringIO.new
      )

      assert_equal 0, first_status
      assert_equal 0, second_status
      assert_equal first_content, File.binread(output)
      assert_equal "Newsletter draft written to #{output}\n", stdout.string
      assert_empty stderr.string
    end
  end

  def test_cli_rejects_missing_month_with_a_useful_error
    stderr = StringIO.new

    status = Newsletter.run([], data_file: FIXTURE, stdout: StringIO.new, stderr: stderr)

    assert_equal 1, status
    assert_equal "Missing required option: --month YYYY-MM\n", stderr.string
  end

  def test_invalid_data_does_not_overwrite_an_existing_draft
    Dir.mktmpdir do |directory|
      output = File.join(directory, 'newsletter.md')
      invalid_data = File.join(directory, 'invalid.yml')
      File.write(output, 'editorial changes')
      File.write(invalid_data, "not: an array\n")
      stderr = StringIO.new

      status = Newsletter.run(
        ['--month', '2026-11', '--output', output],
        data_file: invalid_data,
        stdout: StringIO.new,
        stderr: stderr
      )

      assert_equal 1, status
      assert_equal 'editorial changes', File.read(output)
      assert_includes stderr.string, 'Expected an array'
    end
  end

  def test_cli_rejects_output_outside_allowed_roots
    stderr = StringIO.new

    status = Newsletter.run(
      ['--month', '2026-11', '--output', '/etc/newsletter.md'],
      data_file: FIXTURE,
      stdout: StringIO.new,
      stderr: stderr
    )

    assert_equal 1, status
    assert_includes stderr.string, 'Output path must be inside'
  end

  def test_cli_rejects_an_existing_output_symlink
    Dir.mktmpdir do |directory|
      protected_file = File.join(directory, 'protected.md')
      output = File.join(directory, 'newsletter.md')
      File.write(protected_file, 'keep this content')
      File.symlink(protected_file, output)
      stderr = StringIO.new

      status = Newsletter.run(
        ['--month', '2026-11', '--output', output],
        data_file: FIXTURE,
        stdout: StringIO.new,
        stderr: stderr
      )

      assert_equal 1, status
      assert_equal 'keep this content', File.read(protected_file)
      assert File.symlink?(output)
      assert_includes stderr.string, 'Output path must not be a symlink'
    end
  end

  private

  def event_with(name:, status: '', url: 'https://example.com/event')
    Newsletter::Event.new(
      source: {
        'name' => name,
        'location' => 'Online',
        'dates' => 'November 18, 2026',
        'url' => url,
        'status' => status
      },
      start_date: Date.new(2026, 11, 18),
      end_date: Date.new(2026, 11, 18)
    )
  end
end
