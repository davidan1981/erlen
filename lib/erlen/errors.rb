module Erlen
  class ErlenError < StandardError; end
  class ValidationError < ErlenError;
    attr_accessor :errors

    # Constructs an error with multiple error messages
    def self.from_errors(errors)
      e = self.new
      e.errors = errors
      e
    end
  end
  class InvalidPayloadError < ErlenError; end
  class InvalidRequestError < ErlenError; end
  class InvalidResponseError < ErlenError; end
  class NoPayloadError < ErlenError; end
  class NoAttributeError < ErlenError; end
  class SchemaNotDefinedError < ErlenError; end
end
