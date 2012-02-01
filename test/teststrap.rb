require 'riot'
require 'riot/rr'

DEVELOPMENT_MODE = true
ROOT_PATH = EXTRACT_PATH = File.expand_path("../../", __FILE__)

require_relative '../lib/main'

Log.level = :WARNING # Don't print out junk.

if ARGV.include? "--verbose" or ARGV.include? "-v"
  Riot.verbose
else
  Riot.pretty_dots
end
