#!/usr/bin/env ruby
require 'yaml'

KNOWS_FILE = Dir.pwd + '/django/src/www/eventbrite/common/automation/webdriver/static_files/knows_out.yml'

# Slurp the YAML file, die if something goes wrong
begin
    data = YAML::load(File.read(KNOWS_FILE))
rescue Exception => e
    puts "Something went wrong with parsing the knows file"
    exit 1
end
# Print out all the relavant tests, or all if there's a lot.
if !ARGV[0].empty?
    # Collect all the tests from the YAML
    tests = ARGV.map{ |file| data[file] }.compact()
    if tests.any? && tests[0].nil?
        # No tests to run, simply exit.
        exit 0
    elsif tests[0].length < 50
        puts "The following acceptance tests are affected by your changes\n"
        tests[0].each do |t|
            puts "- #{t}"
        end
    else
        puts "Your changes affect almost everything. I suggest you run all tests in Sauce"
    end
    exit 0
else
    puts "Error: Nothing was passed to this script"
    exit 1
end
