module Erlen

  # just listing out frequently used schemas as base schemas

  # XXX: this file is a WORK IN PROGRESS!!

  class EmptySchema < BaseSchema
  end

  class AnySchema < BaseSchema
    # allow_subclass true
  end

  class ResourceSchema < BaseSchema
    attribute :created_at, Time
    attribute :updated_at, Time
    attribute :id, Integer
  end

  class ArrayOfLike < BaseSchema
    validate(:validate_elements) do
      @attributes.each_pair do |k, v|
      end
    end
  end

  class ArrayOf
    def self.new(elementSchema)
      Class.new do
      end
    end
  end

  class ResourceListSchema < BaseSchema
    attribute :data, ArrayOf.new(AnySchema)
    attribute :page, Integer
    attribute :page_size, Integer
    attribute :count, Integer
  end

end

