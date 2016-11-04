module Erlen
  # This class is the basis for all schemas. If a schema class inherits this
  # class, it's ready to define attributes. When a schema class inherits
  # from another schema class, it inherits all the attributes defined by the
  # ancestors.
  #
  # By instantiating this class, you will get a "payload" to/from which you
  # can access attribute data. You may validate the payload using #valid?
  # method.
  #
  # @note Be careful when defining a method inside this class. It must use a
  # prefix to avoid conflicts with attribute names that may be defined
  # later by the user.
  class BaseSchema

    # List of error messages
    attr_accessor :errors

    class << self
      # List of schema attribute definitions (pertaining to the class)
      attr_accessor :schema_attributes

      # List of validation procs to run at valid?
      attr_accessor :validator_procs

      # Determines whether subtypeing is allowed (considered valid)
      attr_accessor :subtype_allowed

      # Allows subtype of this schema to be valid. Use this with caution.
      #
      # @param allow [Boolean] if set to true, this schema will allow
      #                        subtypes
      def allow_subtype(allow)
        @@subtype_allowed = allow
      end

      # Defines an attribute for the schema. Must specify the type. If
      # validation block is specified, the block will be executed at
      # validation.
      #
      # @param name [Symbol] the name of attribute
      # @param type [Class] it must be either a primitive type or a
      #                      BaseSchema class.
      # @param opts [Hash, nil] options
      # @param validation [Proc, nil] optinal validation block.
      def attribute(name, type, opts={}, &validation)
        attr = Attribute.new(name.to_sym, type, opts, &validation)
        schema_attributes[name.to_sym] = attr
      end

      # Defines a custom validation block. Must specify message which is
      # used to identify the validation in case of an error.
      #
      # @param message [String, Symbol] a simple message/name of the
      #                                  validation.
      # @param blk [Proc] the validation code block
      def validate(message, &blk)
        validator_procs << [message, blk]
      end

      # Imports from an object. This is different from instantiating the
      # class with a hash or a schema object because it looks for attributes
      # from the specified object gracefully.
      #
      # @param obj [Object] any object
      # @return BaseSchema the concrete schema object.
      def import(obj)
        payload = self.new

        schema_attributes.each_pair do |k, attr|
          obj_attribute_name = attr.obj_attribute_name.to_sym

          default_val = attr.options[:default]
          if obj.class <= BaseSchema # cannot use is_a?
            begin
              attr_val = obj.send(k)
            rescue NoAttributeError => e
              attr_val = default_val || Undefined.new
            end
          else
            if obj.respond_to?(obj_attribute_name)
              attr_val = obj.send(obj_attribute_name)
            else
              attr_val = default_val || Undefined.new
            end
          end

          # private method so use send
          payload.send(:__assign_attribute, k, (attr_val || default_val))
        end

        payload
      end

      def inherited(klass)
        attrs = schema_attributes.nil? ? {} : schema_attributes.clone
        klass.schema_attributes = attrs
        procs = self.validator_procs.nil? ? [] : self.validator_procs.clone
        klass.validator_procs = procs
        klass.subtype_allowed = false # by default
      end

    end

    # There are two ways to initialize a payload: (1) by specifying a Hash
    # or (2) by providing an object that may share some of the attribute
    # names. The initialization is graceful--i.e., no error will be thrown
    # if the source object doesn't have certain attributes OR has additional
    # attributes.
    def initialize(obj = {})
      @valid = nil
      @attributes = {}
      @errors = []

      # TODO: this initialization can be written to be more efficient.

      # Initialize all values to undefined
      self.class.schema_attributes.each_pair do |k, v|
        @attributes[k] = Undefined.new
      end

      if obj.is_a? Hash
        # Bulk assign initial attributes
        obj.each_pair do |k, v|
          __assign_attribute(k, v)
        end

      else
        __init_payload(obj)

      end
    end

    # Checks if a payload is valid or not by validating it against the
    # schema. This check includes type checks, attribute validations, and
    # custom validations.
    #
    # @return [Boolean] true if valid, otherwise false.
    def valid?
      @valid ||= __validate_payload
    end

    # A payload is an instance of a schema only if
    #   - the payload is an instance of the schema
    #   - or the type of payload is a subtype of the specified schema.
    #
    # @param klass [Class] a class object that is a subtype of BaseSchema.
    # @return [Boolean] true if payload is considered of the specified type.
    def is_a?(klass)
      if !(klass <= BaseSchema)
        false
      elsif (klass == self.class)
        true
      elsif klass.subtype_allowed
        # It's a hack but works. If klass allows subtyping, then all we need
        # to do is to attempt to gracefully instantiate it using the current
        # payload.
        payload = klass.import(self)
        payload.valid?
      end
    end

    def method_missing(mname, value=nil)
      if mname.to_s.end_with?('=')
        __assign_attribute(mname[0..-2].to_sym, value)
      else
        raise NoAttributeError.new(mname) unless @attributes.include?(mname.to_sym)

        @attributes[mname.to_sym]
      end
    end

    protected

    def __init_payload(obj)
      raise InvalidRawPayloadError unless obj.class <= BaseSchema # cannot use is_a?
      obj.class.schema_attributes.each_pair do |k, attr|
        v = obj.send(k)
        __assign_attribute(k, v)
      end
    end

    def __validate_payload
      @valid = nil
      @errors.clear
      klass = self.class
      @attributes.each_pair do |k, v|
        klass_attribute = klass.schema_attributes[k]
        begin
          klass_attribute.validate(v)
        rescue ValidationError => e
          @errors << e.message
        end
      end

      klass.validator_procs.each do |m, p|
        begin
          result = p.call(self)
        rescue Exception => e
          @errors << e.message
        else
          @errors << m unless result
        end
      end
      @valid = (@errors.size == 0)
    end

    def __assign_attribute(name, value)
      name = name.to_sym
      raise NoAttributeError unless @attributes.include?(name)

      attr = self.class.schema_attributes[name]
      # value = attr.type.new(value) if attr.type <= BaseSchema

      @valid = nil # a value is dirty so not valid anymore until next validation
      @attributes[name] = value
    end

  end
end
