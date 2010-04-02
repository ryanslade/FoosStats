# Use an in memory sqlite DB in test mode
ENV["DATABASE_URL"] = "sqlite3::memory:"

require File.join(File.dirname(__FILE__), '..', 'foosstats.rb')

require "rubygems"
require "sinatra"
require "rack/test"
require "spec"
require "spec/autorun"
require "spec/interop/test"

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

