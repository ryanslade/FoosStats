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

def setup_db
  DataMapper.auto_migrate!
  4.times do |n|
    Player.create(:first_name => "first#{n}", :last_name => "last#{n}", :email => "test#{n}@test.com")
  end

  # Edge case player
  Player.create(:first_name => "first", :last_name => "last", :email => "test@test.com")

  8.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8) }
  5.times { Game.create(:team_one_attack => 1, :team_one_defense => 2, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 8, :team_two_score => 10) }

  # Same player can be on one team
  Game.create(:team_one_attack => 1, :team_one_defense => 1, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 8, :team_two_score => 10)
  Game.create(:team_one_attack => 1, :team_one_defense => 1, :team_two_attack => 3, :team_two_defense => 4, :team_one_score => 10, :team_two_score => 8)
end