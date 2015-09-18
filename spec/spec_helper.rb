require "bundler"
Bundler.setup

require "rspec"
require "jyske_bank_record"

RSpec.configure do |config|
  config.color = true
  config.formatter = :progress
end
