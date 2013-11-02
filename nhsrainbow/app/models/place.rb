class Place < ActiveRecord::Base
  attr_accessible :description, :latitude, :longitude, :name, :place_type
end
