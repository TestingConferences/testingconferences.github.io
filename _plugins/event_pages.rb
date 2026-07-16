# Generate one internal, indexable page for every upcoming event.
require "date"

module TestingConferences
  class EventPage < Jekyll::Page
    def initialize(site, event)
      slug = Jekyll::Utils.slugify(event.fetch("name"))
      @site = site
      @base = site.source
      @dir = File.join("events", slug)
      @name = "index.html"
      process(@name)
      read_yaml(File.join(@base, "_layouts"), "event.html")

      start_date, end_date = parse_dates(event.fetch("dates"))
      description = "#{event.fetch("name")} is a software testing conference or workshop in #{event.fetch("location")}."
      data["title"] = "#{event.fetch("name")} | Software Testing Conferences"
      data["description"] = description
      data["event"] = event.merge(
        "description" => description,
        "start_date" => start_date.iso8601,
        "end_date" => end_date.iso8601,
        "schema" => schema(event, description, start_date, end_date)
      )
      data["permalink"] = "/events/#{slug}/"
    end

    private

    def parse_dates(value)
      if value =~ /\A(.+?)\s+(\d{1,2})-(\d{1,2}),\s+(\d{4})\z/
        month, first, last, year = Regexp.last_match.captures
        [Date.parse("#{month} #{first}, #{year}"), Date.parse("#{month} #{last}, #{year}")]
      elsif value =~ /\A(.+?)\s+(\d{1,2}),\s+(\d{4})\z/
        date = Date.parse(value)
        [date, date]
      else
        raise "Unsupported event date format: #{value}"
      end
    end

    def schema(event, description, start_date, end_date)
      location = event.fetch("location")
      location_data = if location.casecmp("online").zero?
        { "@type" => "VirtualLocation", "url" => event.fetch("url") }
      else
        { "@type" => "Place", "name" => location }
      end

      {
        "@context" => "https://schema.org",
        "@type" => "Event",
        "name" => event.fetch("name"),
        "description" => description,
        "url" => "#{@site.config.fetch("url")}/events/#{Jekyll::Utils.slugify(event.fetch("name"))}/",
        "sameAs" => event.fetch("url"),
        "startDate" => start_date.iso8601,
        "endDate" => end_date.iso8601,
        "eventAttendanceMode" => attendance_mode(location),
        "eventStatus" => "https://schema.org/EventScheduled",
        "location" => location_data,
        "organizer" => {
          "@type" => "Organization",
          "name" => @site.config.fetch("title"),
          "url" => @site.config.fetch("url")
        }
      }
    end

    def attendance_mode(location)
      return "https://schema.org/OnlineEventAttendanceMode" if location.casecmp("online").zero?
      return "https://schema.org/MixedEventAttendanceMode" if location.downcase.include?("online")

      "https://schema.org/OfflineEventAttendanceMode"
    end
  end

  class EventPageGenerator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      site.data.fetch("current", []).each do |event|
        site.pages << EventPage.new(site, event)
      end
    end
  end
end
