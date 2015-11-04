class Link
  include Mongoid::Document
  include Geocoder::Model::Mongoid

  field :text, type: String
  field :latitude, type: Float
  field :longitude, type: Float
  field :coordinates, :type => Array
  field :origin, type: String
  field :place_id, type: String
  geocoded_by :not_an_existing_field
  after_validation :set_missing_fields

  def relevance(context)
    self.distance_from [context[:latitude], context[:longitude]]
  end

  def self.nearby(context)
    links = Link.all.select { |l| l.geocoded? && l.distance_from([context[:latitude], context[:longitude]]) < Link.max_radius }
    google_places_result = HTTParty.get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyCSdMKcdPKJbzYunFO7-15dCZdEwkYPDVM&location=#{context[:latitude]},#{context[:longitude]}&radius=#{Link.max_radius}")
    google_places = JSON.parse(google_places_result.body)["results"].collect { |r|
      Link.new({ text: r["name"], coordinates: [r["geometry"]["location"]["lng"], r["geometry"]["location"]["lat"]], place_id: r["place_id"], origin: "google_places" })
    }
    links.concat(google_places).sort_by { |l| l.relevance(context) }
  end

  def self.max_radius
    1
  end

  def set_missing_fields
    self.coordinates = [self.longitude, self.latitude]
    self.origin = "database"
    self.place_id = ""
  end
end
