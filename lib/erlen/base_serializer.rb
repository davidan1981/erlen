module Erlen
  class BaseSerializer
    def self.data_to_payload(data, schemaClass)
      data = convert_hash_keys(data)

      schemaClass.new(data)
    end

    def self.payload_to_data(payload)
      return nil unless payload.valid?
      attrs = payload.class.schema_attributes

      Hash[attrs.map { |k, attr| [attr.name, payload.send(k)] }]
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
