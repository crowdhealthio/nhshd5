require 'open-uri'

class Place < ActiveRecord::Base
  attr_accessible :description, :latitude, :longitude, :name, :place_type, :foursquare_id, :nhs_id

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
  	postcode = Place::find_postcode(lat, long).gsub!(/\s+/, "")
  	venues = []
    service_types = NhsType.all
    hydra = Typhoeus::Hydra.new
    requests = Array.new
    places_requests = Array.new
    service_types.each do |service_type|
      requests.push(Typhoeus::Request.new("http://v1.syndication.nhschoices.nhs.uk/services/types/#{service_type.uri_key}/postcode/#{postcode}.xml?apikey=NOTKAXDM&range=1"))
    end
    requests.map { |request| hydra.queue(request) }
    hydra.run
    hydra2 = Typhoeus::Hydra.new
    requests.each do |request|
      doc = Nokogiri::XML(request.response.body)
      doc.css('entry').each do |entry|
        places_requests.push(Typhoeus::Request.new("#{entry.css('id').text}.xml?apikey=NOTKAXDM"))
      end
    end
    places_requests.map { |request| hydra2.queue(request) }
    hydra2.run
    places_requests.each do |request|
        doc = Nokogiri::XML(request.response.body).remove_namespaces!
        doc.css('feed').each do |entry|
          place_lat = entry.css('latitude').text.to_f
          place_lng = entry.css('longitude').text.to_f
          name = entry.css('deliverer').text
          if name.empty?
            remove_intro = entry.css('title').text[14..-1]
            name = remove_intro[0..remove_intro.size/2-1]
          end
          place = Place.place_with_name_within_radius(name, 1000, place_lat, place_lng)
          if !place
            place = Place.find_or_create_by_name_and_nhs_id(
             :name => name,
             :nhs_id => URI.parse(entry.css('id').text).path.split("/").last)
            place.latitude = place_lat
            place.longitude = place_lng
            place.save
          end
          venues << place
        end
    end
    venues
  end

  def self.distance place1, latitude, longitude
  a = [place1.latitude, place1.longitude]
  b = [latitude, longitude]
  rad_per_deg = Math::PI/180  # PI / 180
  rkm = 6371                  # Earth radius in kilometers
  rm = rkm * 1000             # Radius in meters

  dlon_rad = (b[1]-a[1]) * rad_per_deg  # Delta, converted to rad
  dlat_rad = (b[0]-a[0]) * rad_per_deg

  lat1_rad, lon1_rad = a.map! {|i| i * rad_per_deg }
  lat2_rad, lon2_rad = b.map! {|i| i * rad_per_deg }

  a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
  c = 2 * Math.asin(Math.sqrt(a))

  rm * c # Delta in meters
  end

  def self.place_with_name_within_radius(name, radius, latitude, longitude)
    places = Place.where(name: name)
    places.each do |place|
      return place if Place.distance(place, latitude, longitude) < radius 
    end
    nil
  end
end
