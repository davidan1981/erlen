require 'json'
require_relative 'base_serializer'

module Erlen
  class JSONSerializer < BaseSerializer
    def self.from_json(json, schemaClass)
      data = JSON.parse(json)

      data_to_payload(data, schemaClass)
    end

    def self.to_json(payload)
      data = payload_to_data(payload)
      data.to_json if data
    end
  end
end
