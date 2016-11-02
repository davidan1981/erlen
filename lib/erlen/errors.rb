module Erlen
  class ValidationError < StandardError;
    attr_accessor :errors

    # Constructs an error with multiple error messages
    def self.from_errors(errors)
      e = self.new
      e.errors = errors
    end
  end
  class InvalidRawPayloadError < StandardError; end
  class NoAttributeError < StandardError; end
  class NoPayloadError < StandardError; end
  class SchemaNotDefinedError < StandardError; end
end
