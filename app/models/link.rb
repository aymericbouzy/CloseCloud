class Link
  include Mongoid::Document

  field :text, type: String
  field :url, type: String
  field :created_at, type: Time
  field :latitude, type: Float
  field :longitude, type: Float
  field :valid_for, type: Time
  field :radius, type: Float

  def relevance(latitude, longitude)
    radius / (self.distance_to(latitude, longitude))
  end

  def self.nearby(latitude, longitude)
    relevant_links = Link.all.select { |l| l.distance_to(latitude, longitude) < max_radius }
    relevant_links.sort_by { |l| l.relevance(latitude, longitude) }
  end

  def max_radius
    20
  end
end
