module Erlen
  class RailsError < StandardError
    attr_accessor :errors

    def self.from_errors(errors)
      e = self.new
      e.errors = errors
      e
    end

    def message
      errors ?  "#{super}: #{errors.join("\n")}" : super
    end
  end
  class InvalidRequestError < RailsError; end
  class InvalidResponseError < RailsError; end
end
