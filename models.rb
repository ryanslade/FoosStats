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
    property "#{team}_attack".to_sym, Integer, :min => 1
    property "#{team}_defense".to_sym, Integer, :min => 1
    property "#{team}_score".to_sym, Integer, :default => 0

    belongs_to "#{team}_attacker".to_sym, Player, :child_key => ["#{team}_attack".to_sym]
    belongs_to "#{team}_defender".to_sym, Player, :child_key => ["#{team}_defense".to_sym]
  end

  validates_with_method :check_scores
  validates_with_method :check_player_cannot_be_on_both_teams

  def created_at_friendly
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def self.by_date
    #all(:order => [ :created_at.desc ])
    # Seems Time.now is only accurate to the second so tests were all being created at the "same" time
    all(:order => [ :id.desc ])
  end

  def self.recent(limit=10)
    by_date.all(:limit => limit)
  end

  private

  def check_scores
    (team_one_score == 10 || team_two_score == 10) ? true : [false, "At least one team should have a score of 10"]
  end

  def check_player_cannot_be_on_both_teams
    [team_one_attack, team_one_defense].any? { |p| [team_two_attack, team_two_defense].include?(p) } ? [false, "A player cannot be on both teams"] : true
  end
end

class PlayerStats
  attr_reader :played, :wins, :losses, :ratios, :streaks, :longest_wins, :longest_losses, :average_goals_scored

  def initialize()
    @games = Game.by_date
    @played = Hash.new(0)
    @wins = Hash.new(0)
    @losses = Hash.new(0)
    @ratios = Hash.new(0)
    @streaks = Hash.new("")
    @longest_wins = []
    @longest_losses = []
    @average_goals_scored = Hash.new(0)

    calculate_wins_and_streaks
    calculate_win_loss_ratios
    calculate_longest_streaks("longest_wins", /W+/)
    calculate_longest_streaks("longest_losses", /L+/)
    calculate_average_goals
    trim_streaks
  end

  private

  def calculate_longest_streaks(target_instance_variable, regex)
    longest = 0
    streaks = {}
    @streaks.each do |k,v|
      count = v.scan(regex).collect { |e| e.length }.sort.last
      longest = count if count && count > longest
      streaks[count] = streaks[count] ? streaks[count] << k : [k]
    end
    instance_variable_set("@#{target_instance_variable}", [longest, streaks[longest]])
  end

  def trim_streaks(n=10)
    @streaks.each { |k,v| @streaks[k] = v[0,n] }
  end

  def calculate_wins_and_streaks
    for game in @games do
      winning_team = game.team_one_score > game.team_two_score ? "team_one" : "team_two"
      losing_team  = game.team_one_score < game.team_two_score ? "team_one" : "team_two"

      winning_players = [game.send(winning_team+"_attack"), game.send(winning_team+"_defense")].uniq
      losing_players = [game.send(losing_team+"_attack"), game.send(losing_team+"_defense")].uniq

      for player in winning_players do
        @wins[player] += 1
        @streaks[player] += "W"
      end

      for player in losing_players do
        @losses[player] += 1
        @streaks[player] += "L"
      end

      (winning_players+losing_players).each { |p| @played[p] += 1 }
    end
  end

  def calculate_win_loss_ratios
    (@wins.keys+@losses.keys).uniq.each { |k| @ratios[k] = @wins[k].to_f / @losses[k] }
  end
  
  def calculate_average_goals
    goals_scored = {}
    for game in @games do
      goals_scored[game.team_one_attack] = [] unless goals_scored[game.team_one_attack]
      goals_scored[game.team_two_attack] = [] unless goals_scored[game.team_two_attack]
      
      goals_scored[game.team_one_attack] << game.team_one_score
      goals_scored[game.team_two_attack] << game.team_two_score
    end
    goals_scored.each { |k,v| @average_goals_scored[k] = average(v) }
  end
  
  private
  
  def average(arr)
    arr.inject(0) { |mem, var| mem+var }.to_f / arr.length
  end
end
