require 'open-uri'
namespace :import_nhs_types do

  task :fetch => :environment do
    nhs_types_json = open("http://v1.syndication.nhschoices.nhs.uk/services/types.json?apikey=NOTKAXDM")
    parsed_json = ActiveSupport::JSON.decode(nhs_types_json)
    parsed_json.each do |type_json|
      parser = URI::Parser.new
      NhsType.create(:name => type_json["Text"],
      			     :uri_key => URI.parse(type_json["Uri"]).path.split("/").last)
    end
  end
end