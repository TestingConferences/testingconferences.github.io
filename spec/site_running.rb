require 'selenium-webdriver'
require 'rspec/expectations'
include ::RSpec::Matchers

def setup
  @driver = Selenium::WebDriver.for :firefox
end

def teardown
  @driver.quit
end

def run
  setup
  yield
  teardown
end

run do
  @driver.get 'http://testingconferences.org/'
  heading_text = @driver.find_element(class: 'site-title').text
  expect(heading_text).to eql 'Software Testing Conferences'
end
