require File.dirname(__FILE__) + '/spec_helper'

describe "Match" do
  def app
    @app ||= Sinatra::Application
  end

  before :all do
    setup_db
  end
  
  it "should have many games" do
    Match.create
    match = Match.first
    match.games.length.should == 0
    match.games << Game.first
    match.games.length.should == 1
    Match.first.destroy
  end
  
  it "should be nil if not added to game yet" do
    g = Game.first
    g.match.should == nil
  end
  
  it "should remove game id's when match is removed" do
    match = Match.create
    match.games.length.should == 0
    match.games << Game.first
    match.save
    Game.first.match.id.should == match.id
    Match.first.destroy
    Game.first.match.should == nil
  end
  
  it "should only allow game with the same players" do
    players = []
    games = []
    5.times { |n| players << Player.create(:first_name => "mf#{n+1}", :last_name => "ml#{n+1}", :email => "matchtest#{n+1}@test.com") }
    games << Game.create(:team_one_attack => players[0].id, 
                         :team_one_defense => players[1].id, 
                         :team_two_attack => players[2].id, 
                         :team_two_defense => players[3].id, 
                         :team_one_score => 10, 
                         :team_two_score => 8)
    
    games << Game.create(:team_one_attack => players[0].id, 
                         :team_one_defense => players[1].id, 
                         :team_two_attack => players[2].id, 
                         :team_two_defense => players[4].id, 
                         :team_one_score => 10, 
                         :team_two_score => 8)

    match = Match.create
    games.each { |g| match.games << g }
    match.valid?.should be false
    
    # Rollback
    players.each { |p| p.destroy }
    games.each { |g| g.destroy }
    match.destroy
  end
  
end