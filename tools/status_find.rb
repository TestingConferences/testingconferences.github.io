require 'yaml'

yaml_data = File.read('../_data/current.yml')
events = YAML.safe_load(yaml_data)

print 'Enter the status: '
input_status = gets.chomp.downcase

filename = input_status + '_conferences.txt'

filtered_events = events.select do |event|
    status = event['status']
    next false unless status.is_a?(String)

    status = status.downcase
    status.include?(input_status)
end

filtered_events.each { |conference| conference.delete('twitter') }

modified_yaml_data = YAML.dump(filtered_events)

File.write(filename, modified_yaml_data)

puts "Output saved to #{filename}"