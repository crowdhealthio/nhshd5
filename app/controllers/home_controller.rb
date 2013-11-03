class HomeController < ApplicationController
  autocomplete :tags, :name, :full => true
  def index
  end
end