require File.dirname(__FILE__) + '/spec_helper'

describe "Match" do
  def app
    @app ||= Sinatra::Application
  end

  before(:all) do
    setup_db
  end
  
  it "should have many games" do
    Match.create
    match = Match.get(1)
    match.games.length.should == 0
    match.games << Game.first
    match.games.length.should == 1
  end
  
end