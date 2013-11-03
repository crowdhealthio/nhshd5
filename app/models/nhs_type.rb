class NhsType < ActiveRecord::Base
  attr_accessible :name, :uri_key
  validates :name, uniqueness: true
end