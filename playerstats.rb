require "helpers"
require "set"

class PlayerStats
  attr_reader :played, :wins, :losses, :ratios, :streaks, :longest_wins, :longest_losses
  attr_reader :average_goals_scored, :average_goals_conceded, :most_popular_teammates, :most_popular_opponents
  attr_reader :humiliation_percentage, :wins_percentage
  attr_reader :match_wins, :match_losses, :match_total, :match_ratios, :match_wins_percentage

  def initialize(options={})
    options[:players] ||= []
    raise "Should be initialsed with 0, 1 or 2 players" unless [0,1,2].include?(options[:players].length)

    @games = case options[:players].length
    when 0
      Game.by_date
    when 1
      Game.with_player(options[:players].first)
    when 2
      Game.by_date.versus(options[:players])
    end
    
    @matches = Match.all
    @match_wins = Hash.new(0)
    @match_losses = Hash.new(0)
    @match_total = Hash.new(0)
    @match_ratios = Hash.new(0)
    @match_wins_percentage = Hash.new(0)

    @players = Player.all

    @played = Hash.new(0)
    @wins = Hash.new(0)
    @losses = Hash.new(0)
    @ratios = Hash.new(0)
    @humiliations = Hash.new(0)
    @humiliation_percentage = Hash.new(0)
    @wins_percentage = Hash.new(0)

    @streaks = {}
    for player in @players
      @streaks[player.id] = Streak.new
    end

    @longest_wins = []
    @longest_losses = []
    @average_goals_scored = Hash.new(0)
    @average_goals_conceded = Hash.new(0)
    @most_popular_teammates = {}
    @most_popular_opponents = {}

    calculate_wins_and_streaks
    calculate_match_wins
    calculate_win_loss_ratios
    calculate_average_goals_and_most_popular
    calculate_longest_streaks("@longest_wins", "longest_win")
    calculate_longest_streaks("@longest_losses", "longest_loss")
    calculate_percentages
  end

  private

  def calculate_match_wins
    for match in @matches do
      games = match.games
      wins = Hash.new(0)
      losses = Hash.new(0)
      played = Hash.new(0)
      all_players = []
      
      for game in games do
        winning_team = game.team_one_score > game.team_two_score ? "team_one" : "team_two"
        losing_team  = game.team_one_score < game.team_two_score ? "team_one" : "team_two"

        winning_players = [game.send(winning_team+"_attack"), game.send(winning_team+"_defense")].uniq
        losing_players = [game.send(losing_team+"_attack"), game.send(losing_team+"_defense")].uniq
        all_players += (winning_players + losing_players)
        
        winning_players.each { |p| wins[p] += 1 }
      end
      
      all_players.uniq!
      
      wins = wins.sort { |a, b| a[1] <=> b[1] }.reverse
      match_winners = [wins[0][0], wins[1][0]]
      match_losers = all_players - match_winners
      
      match_winners.each { |p| @match_wins[p] += 1 }
      match_losers.each { |p| @match_losses[p] += 1 }
      all_players.each { |p| @match_total[p] += 1 }
    end
  end

  def calculate_percentages
    @humiliations.each { |k,v| @humiliation_percentage[k] = (@humiliations[k].to_f / @played[k])*100 }
    @wins.each { |k,v| @wins_percentage[k] = (@wins[k].to_f / @played[k])*100 }
    @match_wins.each { |k,v| @match_wins_percentage[k] = (@match_wins[k].to_f / @match_total[k])*100 }
  end

  def calculate_longest_streaks(target_instance_variable, method)
    totals = {}
    @streaks.each do |k,v|
      totals[v.send(method)] ||= []
      totals[v.send(method)] << k
    end
    instance_variable_set(target_instance_variable, totals.sort { |a, b| b[0] <=> a[0] }.first)
  end

  def calculate_wins_and_streaks
    for game in @games do
      winning_team = game.team_one_score > game.team_two_score ? "team_one" : "team_two"
      losing_team  = game.team_one_score < game.team_two_score ? "team_one" : "team_two"

      winning_players = [game.send(winning_team+"_attack"), game.send(winning_team+"_defense")].uniq
      losing_players = [game.send(losing_team+"_attack"), game.send(losing_team+"_defense")].uniq

      for player in winning_players do
        @streaks[player] = Streak.new unless @streaks[player]
        @wins[player] += 1
        @streaks[player].all += "W"
      end

      for player in losing_players do
        @streaks[player] = Streak.new unless @streaks[player]
        @losses[player] += 1
        
        if (game.send(losing_team+"_score") < 5)
          @streaks[player].all += "H"
          @humiliations[player] += 1
        else
          @streaks[player].all += "L"
        end
      end

      (winning_players+losing_players).each { |p| @played[p] += 1 }
    end
  end

  def calculate_win_loss_ratios
    (@wins.keys+@losses.keys).uniq.each { |k| @ratios[k] = @wins[k].to_f / @losses[k] }
    (@match_wins.keys+@match_losses.keys).uniq.each { |k| @match_ratios[k] = @match_wins[k].to_f / @match_losses[k] }
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

class Streak
  attr_accessor :all
  attr_reader :recent
  attr_reader :longest_win
  attr_reader :longest_loss

  def initialize
    @all = ""
  end

  def recent(limit=10)
    all[0,limit]
  end

  def longest_win
    calculate_longest_streaks(/W+/) || 0
  end

  def longest_loss
    calculate_longest_streaks(/[LH]+/) || 0
  end

  private

  def calculate_longest_streaks(regex)
    @all.scan(regex).collect { |e| e.length }.sort.last
  end
end
