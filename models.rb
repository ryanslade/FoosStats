require "datamapper"
require "dm-validations"
require "rdiscount"

#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/stats.db")

class Player
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :created_at, DateTime, :default => lambda { Time.now.utc }

  property :first_name, String, :required => true
  property :last_name, String, :required => true
  property :email, String, :format => :email_address
  property :description, Text, :default => ""

  def description
    RDiscount.new(attribute_get(:description)).to_html
  end

  def raw_description
    attribute_get(:description)
  end

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
    # Seems Time.now is only accurate to the second so tests were all being created at the "same" time
    all(:order => [ :id.desc ])
  end

  def self.recent(limit=10)
    limit == :all ? by_date : by_date.all(:limit => limit)
  end

  def self.versus(players)
    first  = all(:conditions => ["(team_one_attack = ? OR team_one_defense = ?) AND (team_two_attack = ? OR team_two_defense = ?)", players[0], players[0], players[1], players[1]])
    second = all(:conditions => ["(team_one_attack = ? OR team_one_defense = ?) AND (team_two_attack = ? OR team_two_defense = ?)", players[1], players[1], players[0], players[0]])
    first + second
  end

  def self.with_player(player_id)
    ["team_one_attack", "team_two_attack", "team_one_defense", "team_two_defense"].collect { |q| all(:conditions => ["#{q} = ?", player_id]) }.inject { |m, v| m += v }  
  end

  private

  def check_scores
    (team_one_score == 10 || team_two_score == 10) ? true : [false, "At least one team should have a score of 10"]
  end

  def check_player_cannot_be_on_both_teams
    [team_one_attack, team_one_defense].any? { |p| [team_two_attack, team_two_defense].include?(p) } ? [false, "A player cannot be on both teams"] : true
  end
end
