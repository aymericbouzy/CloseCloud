class Link
  include Mongoid::Document

  field :text, type: String
  field :latitude, type: Float
  field :longitude, type: Float

  def relevance
    self.created_at
  end
end
