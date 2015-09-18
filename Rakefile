require "bundler"
Bundler.setup

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

gemspec = eval(File.read("jyske_bank_record.gemspec"))

task :build => "#{gemspec.full_name}.gem"

file "#{gemspec.full_name}.gem" => gemspec.files + ["jyske_bank_record.gemspec"] do
  system "gem build jyske_bank_record.gemspec"
end
