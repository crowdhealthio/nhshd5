require 'open-uri'
class Place < ActiveRecord::Base
  attr_accessible :description, :latitude, :longitude, :name, :place_type

  @client_id     = 'MIWYYAX3URRPFV3OJTT041F5QIIE1E5GRDNAQ0CLFACR5GHS'
  @client_secret = 'SPQB2PD13XMQVTWT0KFJGORE2OBBOARCCPR5RI0DT0JTSVBI'

  def self.find_from_foursquare(lat = nil, long = nil)
    client = Foursquare2::Client.new(:client_id => @client_id, :client_secret => @client_secret)

    locations = []

    @venues = client.search_venues(ll: "#{lat}, #{long}")
    @venues.groups[0].items.each do |venue|

      geo = "#{venue.location.lat},#{venue.location.lng}"

      locations << venue if valid_category?(venue.categories.first)
    end

    locations
  end

  def self.valid_category?(category)
    return false if category.nil?
    @valid_categories.include?(category.name)
  end

  @valid_categories = [
    "Medical Center",
    "Dentist's Office",
    "Doctor's Office",
    "Emergency Room",
    "Hospital",
    "Laboratory",
    "Optical Shop"
  ]

  def self.find_postcode(lat = nil, long = nil)
  	postcode_json = open("http://uk-postcodes.com/latlng/{lat},{long}.json")
  	postcode_json["postcode"]
  end

  def self.find_nhs_venues(postcode = nil)
  	venues = []
    service_types = NhsType.all
    hydra = Typhoeus::Hydra.new
    requests = Array.new
    service_types.each do |service_type|
      requests.push(Typhoeus::Request.new("http://v1.syndication.nhschoices.nhs.uk/services/types/#{service_type.uri_key}/postcode/#{postcode}.xml?apikey=NOTKAXDM&range=50"))
    end
    requests.map { |request| hydra.queue(request) }
    hydra.run
    requests.each do |request|
       begin
         doc = Nokogiri::XML(request.response.body)
         venues << doc.css('s|serviceDeliverer s|name').first.text
       rescue; end
    end
    venues
  end
end
