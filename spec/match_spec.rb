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
  
  #it "should only allow game with the same player" do
  #  true.should == false
  #end
  
  it "should remove game id's when match is removed" do
    match = Match.create
    match.games.length.should == 0
    match.games << Game.first
    match.save
    Game.first.match.id.should == match.id
    Match.first.destroy
    Game.first.match.should == nil
  end
  
end