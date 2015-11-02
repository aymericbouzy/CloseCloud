class Link
  include Mongoid::Document
  include Geocoder::Model::Mongoid

  field :text, type: String
  field :latitude, type: Float
  field :longitude, type: Float
  field :coordinates, :type => Array
  geocoded_by :not_an_existing_field
  after_validation :set_coordinates

  def relevance(context)
    self.distance_from [context[:latitude], context[:longitude]]
  end

  def self.nearby(context)
    links = Link.all.select { |l| l.geocoded? && l.distance_from([context[:latitude], context[:longitude]]) < Link.max_radius }
    links.sort_by { |l| l.relevance(context) }
  end

  def self.max_radius
    1
  end

  def set_coordinates
    self.coordinates = [self.longitude, self.latitude]
  end
end
