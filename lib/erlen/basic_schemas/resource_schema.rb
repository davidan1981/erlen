module Erlen
  # A resource payload has at least three pre-defined attributes: id,
  # created_at, and updated_at. Use this to represent a database resource.
  class ResourceSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end
end
