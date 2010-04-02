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

  def self.by_date
    all(:order => [ :created_at.desc ])
  end
  
  def self.recent(limit=10)
    by_date.all(:limit => limit)
  end
end

class PlayerStats
  attr_reader :wins, :losses, :ratios, :streaks, :longest_wins, :longest_losses
  
  def initialize()
    @games = Game.by_date
    @wins = Hash.new(0)
    @losses = Hash.new(0)
    @ratios = Hash.new(0)
    @streaks = Hash.new("")
    @longest_wins = []
    @longest_losses = []
    
    calculate_wins_and_streaks
    calculate_win_loss_ratios
    calculate_longest_streaks
    trim_streaks
  end

  private

  def calculate_longest_streaks
    longest_win = 0
    longest_loss = 0
    win_streaks = {}
    loss_streaks = {}
    @streaks.each do |k,v|
      wins = v.scan(/W+/).collect { |e| e.length }.sort.last
      losses = v.scan(/L+/).collect { |e| e.length }.sort.last
      if wins then longest_win = wins if wins > longest_win
      if losses then longest_loss = losses if losses > longest_loss
      
      win_streaks[wins] = win_streaks[wins] ? win_streaks[wins] << k : [k]
      loss_streaks[losses] = loss_streaks[losses] ? loss_streaks[losses] << k : [k]
    end
    @longest_wins = [longest_win, win_streaks[longest_win]]
    @longest_losses = [longest_loss, loss_streaks[longest_loss]]
  end

  def trim_streaks(n=10)
    @streaks.each { |k,v| @streaks[k] = v[0,n] }
  end

  def calculate_wins_and_streaks
    for game in @games do
      winning_team = game.team_one_score > game.team_two_score ? "team_one" : "team_two"
      losing_team  = game.team_one_score < game.team_two_score ? "team_one" : "team_two"

      for position in ["_attack", "_defense"] do
        @wins[game.send(winning_team+position)] += 1
        @losses[game.send(losing_team+position)] += 1
        @streaks[game.send(winning_team+position)] += "W"
        @streaks[game.send(losing_team+position)] += "L"
      end
    end
  end
  
  def calculate_win_loss_ratios
    (@wins.keys+@losses.keys).uniq.each { |k| @ratios[k] = @wins[k].to_f / @losses[k] }
  end
end
