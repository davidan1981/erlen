require 'json'
require_relative 'base_serializer'

module Erlen
  class JSONSerializer < BaseSerializer
    def self.from_json(json, schemaClass)
      data = JSON.parse(json)

      data_to_schema(data, schemaClass)
    end

    def self.to_json(schema)
      schema_to_data(schema).try(:to_json)
    end
  end
end
