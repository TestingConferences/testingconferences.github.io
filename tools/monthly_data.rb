require 'yaml'

yaml_data = File.read('_data/current.yml')
conferences = YAML.safe_load(yaml_data)

print 'Enter the month: '
input_month = gets.chomp.downcase

filename = input_month + '_conferences.txt'

filtered_conferences = conferences.select do |conference|
  dates = conference['dates']
  next false unless dates.is_a?(String)

  month = dates.split(' ')[0]
  month.downcase == input_month
end


filtered_conferences.each { |conference| conference.delete('twitter') }

modified_yaml_data = YAML.dump(filtered_conferences)

File.write(filename, modified_yaml_data)

puts "Output saved to #{filename}"
