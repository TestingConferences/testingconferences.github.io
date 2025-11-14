generate_buffer_posts.rb (tools)

This tool generates a Buffer import CSV from `_data/current.yml`.

Location
- `/tools/generate_buffer_posts.rb` - CLI
- `/tools/lib/generate_buffer_posts.rb` - library (testable)
- `/tools/test/test_generate_buffer_posts.rb` - tests (Minitest)

## Run tests

From the repository root run:

ruby tools/test/test_generate_buffer_posts.rb

## Run the CLI

ruby tools/generate_buffer_posts.rb -i testingconferences.github.io/_data/current.yml -o ~/Downloads/Buffer_Import_Template_generated.csv
