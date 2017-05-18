module Erlen
  class SchemaError < StandardError; end
  class AttributeValidationError < SchemaError; end
  class NoAttributeError < SchemaError; end
  class SchemaNotDefinedError < SchemaError; end
  class InvalidPayloadError < SchemaError; end
end
