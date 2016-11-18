module Erlen
  # This class dynamically generates a concrete schema class that represents
  # a union type of multiple allowed types. Unlike ArrayOf, this does not
  # allow primitive type.
  class AnyOf
    # This class method will return a new class that is catered to the
    # specified schemas. This schema class represents _any_ of the specified
    # schemas. It also works as a proxy to the intended schema payload. The
    # catch is that the payload must be identified at the time of
    # instantiation. That is, at the time of AnyOf instantiation, the
    # purpose (the intended schema) must be clear.
    #
    # @param args [Array] an array of schemas to allow
    # @return [BaseSchema] a dynamically created class <= BaseSchema.
    def self.new(*args)
      allowed_schemas = args
      Class.new(BaseSchema) do |klass|
        class << klass
          attr_accessor :allowed_schemas

          def name
            "AnyOf#{self.allowed_schemas.map {|s| s.name}.join("Or")}"
          end

          def import(obj)
            schema = allowed_schemas.find do |s| s.import(obj).valid? end
            payload = schema.import(obj) if schema
            hash = BaseSerializer.payload_to_hash(payload) if payload
            new(hash)
          end

        end

        klass.allowed_schemas = allowed_schemas

        validate("Schema is not validated as an allowed schema") do |payload|
          !payload.payload.nil? && payload.payload.valid?
        end

        # the actual payload object of the intended schema.
        attr_reader :payload

        def initialize(obj = {})
          __init_inst_vars
          if obj.class <= BaseSchema
            @payload = obj
          elsif obj.is_a? Hash
            __matched_schema_payload(obj)
          end
        end

        def is_a?(schema)
          super || @payload.is_a?(schema)
        end

        def method_missing(mname, value=nil)
          @payload.method_missing(mname, value)
        end

        def to_hash
          @payload.to_hash
        end

        protected

        # Matches the first schema possible and registers the payload
        def __matched_schema_payload(hash)
          self.class.allowed_schemas.each do |s|
            begin
              @payload = s.new(hash)
              break
            rescue
              # nothing
            end
          end
        end
      end
    end
  end

  # Just a shortcut for AnyOf.new
  def self.any_of(*args)
    AnyOf.new(*args)
  end

end
