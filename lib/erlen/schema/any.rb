module Erlen; module Schema
  # This class represents any payload. Any other schema can be a AnySchema
  # instance.
  class Any < Schema::Base
    # Any schema is always valid.
    #
    # @note Even though some attributes may be payloads, no validation
    #       occurs.
    # @return [Boolean] true always
    def valid?; true end

    protected

    # Any schema doesn't validate attributes. Just assign!
    def __assign_attribute(k, v)
      @attributes[k] = v
    end
  end
end; end
