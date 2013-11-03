require 'open-uri'
class Place < ActiveRecord::Base
  attr_accessible :description, :latitude, :longitude, :name, :place_type, :foursquare_id

  @client_id     = 'MIWYYAX3URRPFV3OJTT041F5QIIE1E5GRDNAQ0CLFACR5GHS'
  @client_secret = 'SPQB2PD13XMQVTWT0KFJGORE2OBBOARCCPR5RI0DT0JTSVBI'

  def self.get_from_foursquare_id(id)
    client = Foursquare2::Client.new(:client_id => @client_id, :client_secret => @client_secret)
    venue = client.venue(id)
    place = Place.find_by_foursquare_id(venue.id)
  end

  def self.find_from_coordinates(lat = nil, long = nil)
    locations = Place::find_foursquare_places(lat, long)
    nhs_locations = Place::find_nhs_venues(lat, long)
    locations + nhs_locations
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

  def self.find_foursquare_places(lat = nil, long = nil)
  	
    client = Foursquare2::Client.new(:client_id => @client_id, :client_secret => @client_secret)

    locations = []

    @venues = client.search_venues(ll: "#{lat}, #{long}", radius: 10000000)
    @venues.groups[0].items.each do |venue|

      geo = "#{venue.location.lat},#{venue.location.lng}"
      if valid_category?(venue.categories.first)
        place = Place.find_or_create_by_name_and_foursquare_id(
      				:name => venue.name, 
      				:foursquare_id => venue.id)
        place.place_type = venue.categories.first.name
        place.latitude = venue.location.lat
        place.longitude = venue.location.lng
        place.save
        locations << place
      end
    end
    locations
  end

  def self.find_postcode(lat = nil, long = nil)
  	postcode_json = open("http://uk-postcodes.com/latlng/#{lat},#{long}.json")
  	parsed_json = ActiveSupport::JSON.decode(postcode_json)
  	parsed_json["postcode"]
  end

  def self.find_nhs_venues(lat = nil, long = nil)
  	postcode = Place::find_postcode(lat, long).squish
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
         #TODO do something better here if they are both in foursquare and NHS !
         venues << Place.find_or_create_by_name_and_nhs_id(
         	:name => doc.css('s|serviceDeliverer s|name').first.text,
         	:nhs_id => URI.parse(doc.css('entry id')).path.split("/").last)
       rescue; end
    end
    venues
  end
end
