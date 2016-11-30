module Erlen; module Schema
  # A resource payload has at least three pre-defined attributes: id,
  # created_at, and updated_at. Use this to represent a database resource.
  class Resource < Schema::Base
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end
end; end
