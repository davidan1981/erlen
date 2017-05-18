module Erlen; module Rails
  # This helper module can be included in a controller to define action
  # schemas, which creates before/after action callbacks to validate
  # either/both request or/and response payloads.
  module ControllerHelper
    # This module contains class methods that will extend the class that
    # inherits #ControllerHelper
    module ClassMethods

      # Specifies a schema for the action. If request schema is specified,
      # it will create a before action callback to deserialize and validate the
      # payload. If response schema is specified, it will create a after
      # action callback to serialize and validate the response payload. If
      # render method is used prior to the after action callback, the
      # validation will be skipped during the callback.
      #
      # @param action [String] the name of the action
      # @param request [Schema::Base] the schema for request body
      # @param response [Schema::Base] the schema for response body
      # @param rescue_with [Symbol] the name of rescueing method
      def action_schema(action, request: nil, response: nil, rescue_with: nil)
        __erlen__create_before_action(action, request, response, rescue_with)
        __erlen__create_after_action(action, response, rescue_with)
        nil
      end

      private

      # Generates a method dynamically and adds a before_action hook for the
      # specified action to validate the request body/params.
      def __erlen__create_before_action(action, request_schema, response_schema, rescue_with)
        define_method(:"validate_request_payload_for_#{action}") do
          if rescue_with
            begin
              __erlen__validate_request_payload(request_schema, response_schema)
            rescue ErlenError => e
              send(rescue_with, e)
            end
          else
            __erlen__validate_request_payload(request_schema, response_schema)
          end
        end
        send(:"before_action", :"validate_request_payload_for_#{action}", only: action)
      end

      # Generates a method dynamically and adds an after_action hook for the
      # specified action to validate the response body/params.
      def __erlen__create_after_action(action, schema, rescue_with)
        define_method(:"validate_response_payload_for_#{action}") do
          if rescue_with
            begin
              __erlen__validate_response_payload(schema)
            rescue ErlenError => e
              send(rescue_with, e)
            end
          else
            __erlen__validate_response_payload(schema)
          end
        end
        send(:"after_action", :"validate_request_payload_for_#{action}", only: action)
      end
    end

    # When this module is included, extend the class to have class methods
    # as well.
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # This contains the current action's request schema
    attr_reader :request_schema

    # This contains the current action's response schema
    attr_reader :response_schema

    # Allows rendering of a payload. This operates as the original render if
    # options do not include payload.
    #
    # @note Overridding ActionController::Base#render. Using the exact
    # signature for the method to avoid confusion.
    # http://apidock.com/rails/ActionController/Base/render
    #
    # @param options [Hash]
    # @param extra_options [Hash]
    # @param block [Proc]
    #
    def render(options={}, extra_options={}, &block)
      if options.include?(:payload)
        payload = options.delete(:payload)
        render_payload(payload, options, extra_options=extra_options, &block)
      else
        @validated = false
        @__erlen__response_payload = nil
        super
      end
    end

    # Payload is an instance of Schema::Base class, representing either a
    # request body or response body, validated against the schema. This
    # particular method is only used to retrieve the request payload.
    def request_payload
      @__erlen__request_payload.deep_clone if @__erlen__request_payload
    end

    # Reads the current response payload, an instance of Schema::Base class.
    # You can set this value using render().
    def response_payload
      @__erlen__response_payload.deep_clone if @__erlen__response_payload
    end

    def render_payload(payload, opts={}, extra_opts={}, &blk)
      raise ValidationError.from_errors(payload.errors) unless payload.valid?
      raise ValidationError.new('Response Scheama does not match') if @response_schema && !payload.is_a?(@response_schema)

      opts.update({json: Erlen::Serializer::JSON.to_json(payload)})
      render(opts, extra_opts, &blk) # NOTE: indirect recursion!
      @validated = true # set this after recursive render()
      @__erlen__response_payload = payload
    end

    private

    def __erlen__validate_request_payload(request_schema, response_schema)
      # memoize both of them here
      @request_schema = request_schema
      @response_schema = response_schema
      return unless request_schema
      body = request.body.read
      if body && !body.to_s.empty?
        @__erlen__request_payload = Erlen::Serializer::JSON.from_json(body, request_schema)
      else
        @__erlen__request_payload = request_schema.new
      end
      request.query_parameters.each do |k, v|
        next unless request_schema.schema_attributes.keys.include?(k.to_sym)
        @__erlen__request_payload.send("#{k}=", v)
      end
      raise ValidationError.from_errors(@__erlen__request_payload.errors) unless @__erlen__request_payload.valid?
    rescue JSON::ParserError
      raise InvalidRequestError.new("Could not parse request body")
    end

    def __erlen__validate_response_payload(response_schema)
      return if @validated # no need to re-validate if done already
      json = JSON.parse(response.body)
      @__erlen__response_payload = response_schema.new(json)
      raise ValidationError.from_errors(@__erlen__response_payload.errors) unless @__erlen__response_payload.valid?
    rescue JSON::ParserError
      raise InvalidResponseError.new("Could not parse response body")
    end
  end
end; end
