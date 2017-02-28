module Erlen; module Serializer
  class Base

    def self.hash_to_payload(data, schema)
      warn "[DEPRECATION] `hash_to_payload` is deprecated.  Please use `data_to_payload` instead."
      warn "  #{caller_locations(1).first}"
      data_to_payload(data, schema)
    end

    def self.data_to_payload(data, schema)
      data = convert_data(data)
      schema.new(data)
    end

    def self.payload_to_hash(payload)
      warn "[DEPRECATION] `payload_to_hash` is deprecated.  Please use `payload_to_data` instead."
      warn "  #{caller_locations(1).first}"
      payload_to_data(payload)
    end

    def self.payload_to_data(payload)
      return nil unless payload.valid?
      payload.to_data
    end

    private

    def self.convert_data(value)
      case value
      when Array
        value.map { |v| convert_data(v) }
      when Hash
        Hash[value.map { |k, v| [underscore(k.to_s).to_sym, convert_data(v)] }]
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
end; end
