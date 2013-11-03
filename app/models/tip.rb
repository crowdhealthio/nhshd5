class Tip < ActiveRecord::Base
  attr_accessible :place_id, :tip
  belongs_to :place
end
