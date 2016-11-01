module Erlen
  module ControllerHelper

    # Specifies a schema for the action. If request schema is specified,
    # it will create a before action callback to deserialize and validate the
    # payload. If response schema is specified, it will create a after
    # action callback to serialize and validate the response payload. If
    # render method is used prior to the after action callback, the
    # validation will be skipped during the callback.
    #
    # @param action [String] the name of the action
    # @param request [BaseSchema] the schema for request body
    # @param response [BaseSchema] the schema for response body
    def self.action_schema(action, request: nil, response: nil)
      __erlen__create_before_action(action, request_schema, response_schema)
      __erlen__create_after_action(action, response)
      nil
    end

    def self.__erlen__create_before_action(action, request_schema, response_schema)
      define_method(:"validate_request_schema_for_#{action}") do
        # memoize both of them here
        __erlen__request_schema = request_schema
        __erlen__response_schema = response_schema
        begin
          json = JSON.parse(request.body)
        rescue JSON::ParserError
          raise InvalidRawPayloadError.new("Could not parse request body")
        end
        __erlen__request_payload = request_schema.new(json)
        raise ValidationError.new(__erlen__request_payload.errors) unless __erlen__request_payload.valid?
        check_payload_error!(__erlen__request_payload, request_schema)
      end
      send(:"before_action" :"validate_request_schema_for_#{action}", only: action
    end

    def self.__erlen__create_after_action(action, schema)
      define_method(:"validate_response_schema_for_#{action}") do
        return if __erlen__response_validated
        begin
          json = JSON.parse(response.body)
        rescue JSON::ParserError
          raise InvalidRawPayloadError.new("Could not parse response body")
        end
        __erlen__response_payload = schema.new(json)
        check_payload_error!(__erlen__response_payload, schema)
      end
    end

    private_class_method :__erlen__create_before_action, :__erlen__create_after_action

    attr_accessor :__erlen__response_validated,
                  :__erlen__request_payload,
                  :__erlen__response_payload,
                  :__erlen__request_schema,
                  :__erlen__response_schema

    # Allows rendering of a payload. This operates as the original render if
    # options do not include payload.
    #
    # @note Overridding ActionController::Base#render. Using the exact
    # signature for the method to avoid confusion.
    # http://apidock.com/rails/ActionController/Base/render
    #
    # @params options [Hash]
    # @params extra_options [Hash]
    # @params block [Proc]
    #
    def render(options={}, extra_options={}, &block)
      if options.include?(:payload)
        payload = options.delete(:payload)
        render_schema(payload, options, extra_options=extra_options, &block)
      else
        __erlen__validated = false
        __erlen__response_payload = nil
        super
      end
    end

    # Payload is an instance of BaseSchema class, representing either a
    # request body or response body, validated against the schema. This
    # particular method is only used to retrieve the request payload.
    def request_payload
      raise NoPayloadError if __erlen__request_payload.nil?
      __erlen__request_schema.new(__erlen__request_payload)
    end

    # Reads the current response payload, an instance of BaseSchema class.
    # You can set this value using render().
    def response_payload
      raise NoPayloadError if __erlen__respoonse_paylaod.nil?
      __erlen__response_payload.clone()
    end

    private

    def check_payload_error!(payload, schema)
      raise InvalidRawPayloadError if payload.nil?
      raise ValidationError.new(payload.errors) unless payload.valid?
    end

    def render_schema(payload, opts={}, extra_opts={}, &blk)
      raise SchemaNotDefinedError if __erlen__response_schema.nil?
      raise ValidationError.new(payload.errors) unless payload.valid?
      opts.update({json: Serializer.from_schema_to_json(after_payload))
      render(opts, extra_opts, &blk)
      __erlen__validated = true # set this after recursive render()
    end

  end
end

class FooController
  include Erlen::ControllerHelper

  action_schema(:create, response: JobSchema)
  action_schema(:update, request: JobUpdateSchema, response: JobSchema)
  action_schema(:show, response: JobSchema)
  action_schema(:delete, response: EmptySchema)

  def create
    foo = FooManager.create(request_payload)
    render(payload: foo, status: 201)
  end

  def update
    foo = FooManager.update(request_payload)
    render(payload: foo, status: 200)
  end

end
