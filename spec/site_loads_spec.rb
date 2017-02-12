require 'selenium-webdriver'
require 'rspec/expectations'

describe 'Load Site' do

  def setup

    @driver = Selenium::WebDriver.for :chrome
  end

  def teardown
    @driver.quit
  end

  it 'succeeded' do
    setup

    @driver.get 'http://localhost:4000'
    heading_text = @driver.find_element(class: 'site-title').text
    puts heading_text
    expect(heading_text).to eql 'Software Testing Conferences'

    teardown
  end
end
