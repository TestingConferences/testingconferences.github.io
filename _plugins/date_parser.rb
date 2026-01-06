require 'date'

module Jekyll
  module DateParser
    # Parse human-readable date strings into structured dates
    # Examples:
    # "January 22, 2026" -> { start_date: "20260122", end_date: "20260122" }
    # "January 29 - February 1, 2026" -> { start_date: "20260129", end_date: "20260201" }
    # "February 9-13, 2026" -> { start_date: "20260209", end_date: "20260213" }
    
    def parse_conference_dates(date_string)
      return nil if date_string.nil? || date_string.empty?
      
      # Remove extra spaces and quotes
      date_string = date_string.to_s.strip.gsub(/^"|"$/, '')
      
      begin
        # Pattern: "Month Day, Year" (single day)
        if date_string =~ /^([A-Za-z]+)\s+(\d+),\s+(\d{4})$/
          month = $1
          day = $2.to_i
          year = $3.to_i
          start_date = Date.parse("#{year}-#{month}-#{day}")
          # For ICS format, DTEND should be the day after the event ends
          end_date = start_date + 1
          return {
            'start_date' => start_date.strftime('%Y%m%d'),
            'end_date' => end_date.strftime('%Y%m%d')
          }
        end
        
        # Pattern: "Month Day-Day, Year" (e.g., "February 9-13, 2026")
        if date_string =~ /^([A-Za-z]+)\s+(\d+)-(\d+),\s+(\d{4})$/
          month = $1
          start_day = $2.to_i
          end_day = $3.to_i
          year = $4.to_i
          start_date = Date.parse("#{year}-#{month}-#{start_day}")
          end_date = Date.parse("#{year}-#{month}-#{end_day}")
          # For ICS format, DTEND should be the day after the event ends
          end_date = end_date + 1
          return {
            'start_date' => start_date.strftime('%Y%m%d'),
            'end_date' => end_date.strftime('%Y%m%d')
          }
        end
        
        # Pattern: "Month Day - Month Day, Year" (e.g., "January 29 - February 1, 2026")
        if date_string =~ /^([A-Za-z]+)\s+(\d+)\s+-\s+([A-Za-z]+)\s+(\d+),\s+(\d{4})$/
          start_month = $1
          start_day = $2.to_i
          end_month = $3
          end_day = $4.to_i
          year = $5.to_i
          start_date = Date.parse("#{year}-#{start_month}-#{start_day}")
          end_date = Date.parse("#{year}-#{end_month}-#{end_day}")
          # For ICS format, DTEND should be the day after the event ends
          end_date = end_date + 1
          return {
            'start_date' => start_date.strftime('%Y%m%d'),
            'end_date' => end_date.strftime('%Y%m%d')
          }
        end
        
        # Pattern: "Month Day-Day - Month Day, Year" (e.g., "April 26 - May 1, 2026")
        if date_string =~ /^([A-Za-z]+)\s+(\d+)\s+-\s+([A-Za-z]+)\s+(\d+),\s+(\d{4})$/
          start_month = $1
          start_day = $2.to_i
          end_month = $3
          end_day = $4.to_i
          year = $5.to_i
          start_date = Date.parse("#{year}-#{start_month}-#{start_day}")
          end_date = Date.parse("#{year}-#{end_month}-#{end_day}")
          return {
            'start_date' => start_date.strftime('%Y%m%d'),
            'end_date' => end_date.strftime('%Y%m%d')
          }
        end
        
        # If we can't parse the date, return nil
        return nil
      rescue => e
        # If date parsing fails, return nil
        Jekyll.logger.warn "Date parsing failed for: #{date_string} - #{e.message}"
        return nil
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::DateParser)
