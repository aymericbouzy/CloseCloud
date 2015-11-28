class Link
  include Mongoid::Document
  include Geocoder::Model::Mongoid

  field :text, type: String
  field :latitude, type: Float
  field :longitude, type: Float
  field :coordinates, :type => Array
  field :origin, type: String
  field :place_id, type: String
  field :icon, type: String
  geocoded_by :not_an_existing_field
  after_validation :set_missing_fields

  def relevance(context)
    self.distance_from [context[:latitude], context[:longitude]]
  end

  def self.nearby(context)
    links = Link.all.select { |l|
      l.geocoded? &&
      l.distance_from([context[:latitude], context[:longitude]]) < Link.max_radius &&
      l._id.generation_time > Time.now - 60 * 60 * 24
    }
    types = ["accounting", "airport", "amusement_park", "aquarium", "art_gallery", "atm", "bakery",
      "bank", "bar", "beauty_salon", "bicycle_store", "book_store", "bowling_alley", "bus_station",
      "cafe", "campground", "car_dealer", "car_rental", "car_repair", "car_wash", "casino", "cemetery",
      "church", "city_hall", "clothing_store", "convenience_store", "courthouse", "dentist",
      "department_store", "doctor", "electrician", "electronics_store", "embassy", "establishment",
      "finance", "fire_station", "florist", "food", "funeral_home", "furniture_store", "gas_station",
      "general_contractor", "grocery_or_supermarket", "gym", "hair_care", "hardware_store", "health",
      "hindu_temple", "home_goods_store", "hospital", "insurance_agency", "jewelry_store", "laundry",
      "lawyer", "library", "liquor_store", "local_government_office", "locksmith", "lodging",
      "meal_delivery", "meal_takeaway", "mosque", "movie_rental", "movie_theater", "moving_company",
      "museum", "night_club", "painter", "park", "parking", "pet_store", "pharmacy", "physiotherapist",
      "place_of_worship", "plumber", "police", "post_office", "real_estate_agency", "restaurant",
      "roofing_contractor", "rv_park", "school", "shoe_store", "shopping_mall", "spa", "stadium",
      "storage", "store", "subway_station", "synagogue", "taxi_stand", "train_station", "travel_agency",
      "university", "veterinary_care", "zoo"]
    google_places_result = HTTParty.get("https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyCSdMKcdPKJbzYunFO7-15dCZdEwkYPDVM&location=#{context[:latitude]},#{context[:longitude]}&radius=#{Link.max_radius * 1000}&types=#{types.join('|')}")
    google_places = JSON.parse(google_places_result.body)["results"].collect { |r|
      Link.new({
        text: r["name"],
        coordinates: [r["geometry"]["location"]["lng"], r["geometry"]["location"]["lat"]],
        place_id: r["place_id"],
        origin: "google_places",
        icon: r["icon"]
      })
    }
    links.concat(google_places).sort_by { |l| l.relevance(context) }
  end

  def self.max_radius
    0.1
  end

  def set_missing_fields
    self.coordinates = [self.longitude, self.latitude]
    self.origin = "database"
    self.place_id = ""
    self.icon = ""
  end
end
