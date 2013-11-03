class HomeController < ApplicationController
  def index
    @place = Place.new
  end
end