module Erlen

  # This class represents empty payload.
  class EmptySchema < BaseSchema
  end

  # This class represents any payload. Any other schema can be a AnySchema
  # instance.
  class AnySchema < BaseSchema

    # AnySchema is always valid.
    #
    # @return [Boolean] true always
    def valid?; true end

    protected

    # Any schema doesn't validate attributes. Just assign!
    def __assign_attribute(k, v)
      @attributes[k] = v
    end
  end

  # A resource payload has at least three pre-defined attributes: id,
  # created_at, and updated_at. Use this to represent a database resource.
  class ResourceSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end

  # This class dynamically generates a concrete schema class that represents
  # a union type of multiple allowed types.
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

  def self.any_of(*args)
    AnyOf.new(*args)
  end

  # This class dynamically generates a concrete schema class that represents
  # a collection type with a specific element type.
  class ArrayOf
    # This class method will return a new class that represents a collection
    # schema with the specified element schema. Because of
    # covariance/contravariance issue with a collection type, the element
    # type MUST match in order to be valid. In other words, Floats are not
    # allowed for ArrayOf.new(Integer) because Float != Integer.
    #
    # @param elementSchema [BaseSchema] the schema of the element
    # @return [BaseSchema] a dynamically created class <= BaseClass
    def self.new(elementSchema)
      Class.new(BaseSchema) do |klass|
        class << klass
          attr_accessor :element_schema

          def name
            "ArrayOf#{elementSchema.name}"
          end

          # Imports from an array of objects (or payloads). This is different from
          # instantiating the class with an array hashes or schema objects because it
          # looks for schema attributes from the specified objects gracefully.
          #
          # @param array of objs [Object] any objects
          # @return BaseSchema the concrete schema object.
          def import(obj_elements)
            payload = self.new
            obj_elements.each do |obj|
              payload.elements << element_schema.import(obj)
            end

            payload
          end
        end

        klass.element_schema = elementSchema

        validate("Elements must be #{elementSchema.name}") do |payload|
          payload.elements.index {|e| !e.is_a?(payload.class.element_schema) || !e.valid? }.nil?
        end

        # Composes an array where the values are the data equivelant of each element.
        #
        # @return [Hash] the payload data
        def to_hash
          @elements.map {|e| e.to_hash }
        end

        def initialize(elements=[])
          @elements = elements.to_a
          __init_inst_vars
        end

        # Allows elements to be accessible as a special attribute.
        #
        # @return [Array] an array of payload (must be a specific schema)
        def elements
          @valid = nil # hacky
          @elements
        end

        def is_a?(schema)
          schema <= BaseSchema && schema.respond_to?(:element_schema) &&
              schema.element_schema == self.class.element_schema
        end
      end
    end
  end

  def self.array_of(elementSchema)
    ArrayOf.new(elementSchema)
  end

  # This class dynamically generates a concrete schema class that represents
  # a collection type for resources. It adheres to Hireology's API standard.
  class ResourceListSchema
    def self.new(resourceSchema)
      Class.new(BaseSchema) do
        attribute :data, ArrayOf.new(resourceSchema)
        attribute :page, Integer
        attribute :page_size, Integer
        attribute :count, Integer
      end
    end
  end

end

