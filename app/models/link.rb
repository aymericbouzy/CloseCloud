class Link
  include Mongoid::Document

  field :text, type: String

  def relevance
    self.created_at
  end
end
