module Erlen
  # This class dynamically generates a concrete schema class that represents
  # a collection type for resources. It adheres to Hireology's API standard.
  class ResourceArrayOf
    def self.new(resource_schema)
      Class.new(Schema::Base) do
        attribute :data, Schema::ArrayOf.new(resource_schema), required: true
        attribute :page, Integer
        attribute :page_size, Integer
        attribute :count, Integer
      end
    end
  end
end
