module Erlen
  class BaseSerializer
    def self.data_to_schema(data, schemaClass)
      data = convert_hash_keys(data)

      schemaClass.new(data)
    end

    def self.schema_to_data(schema)
      return nil unless schema.valid?
      attrs = schema.class.schema_attributes

      Hash[attrs.map { |k, attr| [attr.name, schema.send(k)] }]
    end

    private

    def self.convert_hash_keys(value)
      case value
      when Array
        value.map(&:convert_hash_keys)
      when Hash
        Hash[value.map { |k, v| [underscore(k.to_s).to_sym, convert_hash_keys(v)] }]
      else
        value
      end
    end

    def self.underscore(str)
      str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end
