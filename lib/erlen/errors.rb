module Erlen
  class ValidationError < StandardError;
    attr_reader :errors
    def initialize(errors)
      @errors = errors
    end
  end
  class InvalidRawPayloadError < StandardError; end
  class NoAttributeError < StandardError; end
  class NoPayloadError < StandardError; end
  class SchemaNotDefinedError < StandardError; end
end
