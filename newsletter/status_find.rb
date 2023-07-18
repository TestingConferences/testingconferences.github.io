require 'yaml'

yaml_data = File.read('../_data/current.yml')
conferences = YAML.safe_load(yaml_data)

# Want to find / filter the list by certain statuses such as:
# Early Bird
# CFP or Call for Proposal
# These will be partial matches

#I should be prompted to enter in the search phrase