# frozen_string_literal: true
require 'yaml'
require 'date'

module Tools
  class GenerateBufferPosts
    ALLOWED_TIMES = ['10:24', '14:29', '17:48', '22:21']

    def self.rows_from_yaml_string(yaml_string)
      data = YAML.safe_load(yaml_string)
      rows = []

      data.each do |entry|
        name = entry['name']
        dates_field = entry['dates']
        location = entry['location']
        url = entry['url']
        status = entry['status']
        twitter = entry['twitter']

  start_date = parse_start_date(dates_field)
  status_date = extract_date_from_status(status)
  status_summary = extract_status_summary(status)

        build_post = lambda do |target_date, kind|
          return nil unless target_date
          chosen_time = ALLOWED_TIMES.sample
          posting_time = Time.utc(target_date.year, target_date.month, target_date.day, *chosen_time.split(':').map(&:to_i))
          # filter out posts in the past
          return nil if posting_time <= Time.now.utc

          text = case kind
                 when :one_day
                   "#{name} is tomorrow!"
                 when :one_week
                   "One week until #{name}"
                 when :status
                   # use the status text (e.g., "CFP open until Feb 28, 2026") as the post prefix
                   status_summary && !status_summary.empty? ? status_summary : "One week until #{name}"
                 else
                   name.to_s
                 end

          # add additional details
          extras = []
          extras << "(#{dates_field})" if dates_field
          extras << "in #{location}" if location
          extras << "Follow: @#{twitter}" if twitter
          extras << "More: #{url}" if url

          full_text = ([text] + extras).join(' ')

          image_url = ''
          tags = ''

          # Buffer expects posting time in the format: "YYYY-MM-DD HH:MM"
          [full_text, image_url, tags, posting_time.utc.strftime('%Y-%m-%d %H:%M')]
        end

        if start_date
          one_week = build_post.call(start_date - 7, :one_week)
          rows << one_week if one_week
          one_day = build_post.call(start_date - 1, :one_day)
          rows << one_day if one_day
        end

        status_post = build_post.call(status_date - 7, :status) if status_date
        rows << status_post if status_post
      end

      rows
    end

    def self.parse_start_date(dates_str)
      return nil unless dates_str && dates_str.is_a?(String)
      s = dates_str.strip

      months = Date::MONTHNAMES.compact.zip(1..12).to_h.merge(Date::ABBR_MONTHNAMES.compact.zip(1..12).to_h)

      if m = s.match(/([A-Za-z]+)\s+(\d{1,2})\s*-\s*\d{1,2},\s*(\d{4})/)
        month = m[1]
        day = m[2].to_i
        year = m[3].to_i
        mo = months[month]
        return Date.new(year, mo, day) rescue nil
      end

      if m = s.match(/([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})/)
        month = m[1]
        day = m[2].to_i
        year = m[3].to_i
        mo = months[month]
        return Date.new(year, mo, day) rescue nil
      end

      if m = s.match(/([A-Za-z]+)\s+(\d{1,2})\s*-\s*([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})/)
        month = m[1]
        day = m[2].to_i
        year = m[5].to_i
        mo = months[month]
        return Date.new(year, mo, day) rescue nil
      end

      begin
        Date.parse(s)
      rescue
        nil
      end
    end

    def self.extract_date_from_status(status)
      return nil unless status && status.is_a?(String)
      if m = status.match(/([A-Za-z]+\s+\d{1,2},\s*\d{4})/)
        begin
          return Date.parse(m[1])
        rescue
          return nil
        end
      end
      nil
    end

    def self.extract_status_summary(status)
      return '' unless status && status.is_a?(String)
      # Remove any HTML tags and trim
      status.gsub(/<[^>]*>/, '').strip
    end
    # tags removed by request; CSV will emit an empty Tags column
  end
end
