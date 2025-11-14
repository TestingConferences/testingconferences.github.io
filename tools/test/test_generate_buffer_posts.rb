# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../lib/generate_buffer_posts'
require 'set'

class TestGenerateBufferPosts < Minitest::Test
  def sample_yaml
    <<~YAML
    - name: TestConf 2026
      location: Testville
      dates: "March 10-12, 2026"
      url: <a href="https://example.com" target="_blank">Registration is Open</a>
      twitter: testconf
      status: "CFP open until February 28, 2026"
    YAML
  end

  def test_rows_count_and_formats
    rows = Tools::GenerateBufferPosts.rows_from_yaml_string(sample_yaml)

    # Expect 3 posts: one week before start, one day before start, and one week before status date
    assert_equal 3, rows.length

    # Expected posting dates (based on sample dates):
    expected = {
      '2026-03-03' => 'One week until TestConf 2026', # one week before March 10, 2026
      '2026-03-09' => 'TestConf 2026 is tomorrow!',   # one day before March 10, 2026
      '2026-02-21' => 'CFP open until February 28, 2026'  # one week before Feb 28, 2026 (status date) should use status summary
    }

    dates_seen = rows.map { |r| r[3].split(' ').first }
    assert_equal expected.keys.to_set, dates_seen.to_set

    rows.each do |text, image, tags, posting_time|
      date = posting_time.split(' ').first
      assert expected.key?(date), "Unexpected posting date: #{date}"
      assert text.start_with?(expected[date]), "Unexpected prefix for #{date}: #{text}"
      refute_nil text
      assert_equal '', image
      assert_equal '', tags
      # Posting time should be Buffer format: YYYY-MM-DD HH:MM
      assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}/, posting_time)
    end
  end
end

