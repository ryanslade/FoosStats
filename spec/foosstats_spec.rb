require File.dirname(__FILE__) + '/spec_helper'

describe "Foos Stats" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  it "/ should redirect to /games/recent" do
    get "/"
    follow_redirect!
    assert_equal "http://example.org/games/recent", last_request.url
    last_response.should be_ok
  end
end