module Erlen

  # just listing out frequently used schemas as base schemas

  # XXX: this file is a WORK IN PROGRESS!!

  class EmptySchema < BaseSchema
  end

  class AnySchema < BaseSchema

    # AnySchema is always valid.
    #
    # @return [Boolean] true always
    def valid?; true end

    protected

    def __assign_attribute(k, v)
      @attributes[k] = v
    end
  end

  class ResourceSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end

  class AnyOf
    # This class method will return a new class that is catered to the
    # specified schemas. This schema class represents _any_ of the specified
    # schemas.
    #
    # @param args [Array]
    # @return [BaseSchema] a dynamically created class <= BaseSchema.
    def self.new(*args)
      allowed_schemas = args
      Class.new(BaseSchema) do |klass|
        class << klass
          attr_accessor :allowed_schemas

          def name
            "AnyOf#{self.allowed_schemas.map {|s| s.name}.join("_")}"
          end

          def import(obj)
            schema = allowed_schemas.find do |s| s.import(obj).valid? end
            payload = schema.import(obj) if schema
            hash = BaseSerializer.payload_to_data(payload) if payload
            new(hash)
          end
        end

        klass.allowed_schemas = allowed_schemas

        validate("Schema is not validated as an allowed schema") do |payload|
          !payload.matched_schema_payload.nil?
        end

        def initialize(obj = {})
          @obj = obj # placeholder
          __init_inst_vars
        end

        def matched_schema_payload
          self.class.allowed_schemas.find do |s|
            s.new(@obj).valid?
          end
        end

        def is_a?(schema)
          # TODO: Must be transitive. AnyOf(AnyOf(A)) == AnyOf(A), for
          # example.
          super || (self.class.allowed_schemas.any? {|s| s == schema })
        end
      end
    end
  end

  class ArrayOf
    # This class method will return a new class that represents a collection
    # schema with the specified element schema.
    #
    # @param elementSchema [BaseSchema] the schema of the element
    # @return [BaseSchema] a dynamically created class <= BaseClass
    def self.new(elementSchema)
      Class.new(BaseSchema) do |klass|
        class << klass
          attr_accessor :element_schema
        end
        klass.element_schema = elementSchema
        attr_accessor :elements
        validate("Elements must be #{elementSchema.name}") do |payload|
          payload.elements.index {|e| !e.is_a?(payload.class.element_schema) || !e.valid? }.nil?
        end
        def self.name
          "ArrayOf#{elementSchema.name}_#{elementSchema.object_id}"
        end
        def initialize(elements=[])
          @elements = elements
          __init_inst_vars
        end
        def elements
          @valid = nil # hacky
          @elements
        end
        def is_a?(schema)
          schema <= BaseSchema && schema.responds_to?(:element_schema) &&
              schema.element_schema == self.class.element_schema
        end
      end
    end
  end

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

