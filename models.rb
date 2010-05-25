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

  def self.versus(players)
    first  = by_date.all(:conditions => ["(team_one_attack = ? OR team_one_defense = ?) AND (team_two_attack = ? OR team_two_defense = ?)", players[0], players[0], players[1], players[1]])
    second = by_date.all(:conditions => ["(team_one_attack = ? OR team_one_defense = ?) AND (team_two_attack = ? OR team_two_defense = ?)", players[1], players[1], players[2], players[2]])
    first + second
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
  attr_reader :played, :wins, :losses, :ratios, :streaks, :longest_wins, :longest_losses 
  attr_reader :average_goals_scored, :average_goals_conceded, :most_popular_teammates, :most_popular_opponents

  def initialize(players=[])
    raise "Should be initialsed with 0 or 2 players" unless [0,2].include?(players.length)
    @games = (players.length == 2) ? Game.by_date.versus(players) : Game.by_date
    @played = Hash.new(0)
    @wins = Hash.new(0)
    @losses = Hash.new(0)
    @ratios = Hash.new(0)
    @streaks = Hash.new("")
    @longest_wins = []
    @longest_losses = []
    @average_goals_scored = Hash.new(0)
    @average_goals_conceded = Hash.new(0)
    @most_popular_teammates = {}
    @most_popular_opponents = {}

    calculate_wins_and_streaks
    calculate_win_loss_ratios
    calculate_longest_streaks("longest_wins", /W+/)
    calculate_longest_streaks("longest_losses", /L+/)
    calculate_average_goals_and_most_popular
    trim_streaks if players.length != 2
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

  def calculate_average_goals_and_most_popular
    goals_scored = {}
    goals_conceded = {}
    played_with = {}
    played_against = {}

    for game in @games do
      other = {"team_one" => "team_two", "team_two" => "team_one"}
      ["team_one", "team_two"].each do |team|
        goals_scored[game.send(team+"_attack")] = [] unless goals_scored[game.send(team+"_attack")]
        goals_scored[game.send(team+"_attack")] << game.send(team+"_score")

        goals_conceded[game.send(team+"_defense")] = [] unless goals_conceded[game.send(team+"_defense")]
        goals_conceded[game.send(team+"_defense")] << game.send(other[team]+"_score")
        
        ["_attack", "_defense"].each do |pos|
          played_with[game.send(team+pos)] = [] unless played_with[game.send(team+pos)]
          played_against[game.send(team+pos)] = [] unless played_against[game.send(team+"_attack")]
          played_against[game.send(team+pos)] = [] unless played_against[game.send(team+"_defense")]
          played_against[game.send(team+pos)] << game.send(other[team]+"_attack")
          played_against[game.send(team+pos)] << game.send(other[team]+"_defense")
        end
        
        played_with[game.send(team+"_attack")] << game.send(team+"_defense")
        played_with[game.send(team+"_defense")] << game.send(team+"_attack")
      end
    end
    goals_scored.each { |k,v| @average_goals_scored[k] = v.average }
    goals_conceded.each { |k,v| @average_goals_conceded[k] = v.average }
    played_with.each { |k,v| @most_popular_teammates[k] = v.most_common }
    played_against.each { |k,v| @most_popular_opponents[k] = v.most_common }
  end
  
end

# Helpers
class Array
  def average
    self.inject(0) { |mem, var| mem+var }.to_f / self.length
  end
  
  def most_common
    counts = Hash.new(0)
    self.each { |i| counts[i] += 1 }
    sorted = counts.sort { |a,b| a[1]<=>b[1] }
    highest_count = sorted.last[1]
    return nil if highest_count == 0
    sorted.select { |x| x[1] == highest_count }.collect { |x| x[0] }
  end
end
