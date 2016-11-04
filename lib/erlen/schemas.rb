module Erlen

  # just listing out frequently used schemas as base schemas

  # XXX: this file is a WORK IN PROGRESS!!

  class EmptySchema < BaseSchema
  end

  class AnySchema < BaseSchema
    allow_subclass true
  end

  class ResourceSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end

  class OneOf
    def self.new(*args)
      allowed_schemas = args
      klass = Class.new(BaseSchema) do
        @@allowed_schemas = allowed_schemas
        validate("Schema is not validated as an allowed schema") {|payload| !payload.matched_schema.nil? }
        def initialize(obj)
          @obj = obj
          @errors = []
          @attributes = {}
        end
        def self.name
          "OneOf#{@@allowed_schemas.map {|s| s.name}.join("_")}"
        end
        def matched_schema
          index = @@allowed_schemas.index {|s| s.new(@obj).valid? }
          index.nil? ? nil : @@allowed_schemas[index]
        end
        def is_a?(schema)
          super || valid? && @@allowed_schemas.any? do |s|
            s == schema || (s.subclass_allowed && schema <= s) ||
                (schema.subclass_allowed && s <= schema)
          end
        end
      end
      klass
    end
  end

  class ArrayOf
    def self.new(elementSchema)
      Class.new(BaseSchema) do
        @@element_schema = elementSchema
        attr_accessor :elements
        validate("Elements must be #{elementSchema.name}") do |payload|
          payload.elements.index {|e| !e.is_a?(@@element_schema) || !e.valid? }.nil?
        end
        def self.name
          "ArrayOf#{elementSchema.name}_#{elementSchema.object_id}"
        end
        def self.element_schema
          @@element_schema
        end
        def initialize(elements=[])
          @errors = []
          @attributes = {}
          @elements = elements
        end
        def elements
          @valid = nil # hacky
          @elements
        end
        def is_a?(schema)
          schema <= BaseSchema && schema.responds_to?(:element_schema) &&
              schema.element_schema == @element_schema
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

