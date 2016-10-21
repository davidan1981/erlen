module Erlen
  module JSONSerializer
    def self.from_json(json, schemaClass)
      data = JSON.parse(json)
      data = convert_hash_keys(data)

      schemaClass.new(data)
    end

    def self.to_json(schema)
      # magic happens
      # make sure to handle nesting
    end

    private

    def convert_hash_keys(value)
      case value
      when Array
        value.map(&:convert_hash_keys)
      when Hash
        Hash[value.map { |k, v| [k.underscore.to_sym, convert_hash_keys(v)] }]
      else
        value
      end
    end

  end
end
