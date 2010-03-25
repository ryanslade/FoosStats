require "datamapper"
require "dm-validations"

#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/stats.db")

class Player
  
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime, :default => lambda { Time.now.utc }

  property :first_name, String, :required => true
  property :last_name, String, :required => true
  property :email, String, :format => :email_address

  def name
    "#{first_name} #{last_name}"
  end

  def self.order_by_name
    all(:order => [:first_name.asc, :last_name.asc])
  end
  
end

class Game
  
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime, :default => lambda { Time.now.utc }

  ["team_one", "team_two"].each do |team|
    property "#{team}_attack".to_sym, Integer
    property "#{team}_defense".to_sym, Integer
    property "#{team}_score".to_sym, Integer, :default => 0

    belongs_to "#{team}_attacker".to_sym, Player, :child_key => ["#{team}_attack".to_sym]
    belongs_to "#{team}_defender".to_sym, Player, :child_key => ["#{team}_defense".to_sym]
  end

  def created_at_friendly
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def self.recent(limit=10)
    all(:limit => limit, :order => [ :created_at.desc ])
  end
  
end

class PlayerStats
  
  attr_reader :wins
  attr_reader :losses

  def initialize
    @games = Game.all
    @wins = Hash.new(0)
    @losses = Hash.new(0)
    calculate
  end

  private

  def calculate
    for game in @games do
      winner = game.team_one_score > game.team_two_score ? "team_one" : "team_two"
      loser  = game.team_one_score < game.team_two_score ? "team_one" : "team_two"

      for position in ["_attack", "_defense"] do
        @wins[game.send(winner+position)] += 1
        @losses[game.send(loser+position)] += 1
      end
    end
  end
  
end
