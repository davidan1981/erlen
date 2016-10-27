module Erlen
  class BaseSchema

    attr_accessor :errors

    class << self
      attr_accessor :schema_attributes
      attr_accessor :validator_procs

      def inherited(klass)
        attrs = schema_attributes.nil? ? {} : schema_attributes.clone
        klass.schema_attributes = attrs
        procs = self.validator_procs.nil? ? [] : self.validator_procs.clone
        klass.validator_procs = procs
      end

      def attribute(name, type, opts={}, &validation)
        attr = Attribute.new(name.to_sym, type, opts, &validation)
        schema_attributes[name.to_sym] = attr
      end

      def validate(message, &blk)
        validator_procs << [message, blk]
      end
    end

    def initialize(initial_value)
      @valid = nil
      @attributes = {}
      @errors = []

      # Initialize all values to undefined
      self.class.schema_attributes.each_pair do |k, v|
        @attributes[k] = Undefined.new
      end

      if initial_value.is_a? Hash
        # Bulk assign initial attributes
        initial_value.each_pair do |k, v|
          __assign_attribute(k, v)
        end

      else
        init_object(initial_value)

      end
    end

    def init_object(obj)
      self.class.schema_attributes.each_pair do |k, attr|
        method_name = attr.method_name.to_sym

        default_val = attr.options[:default]
        attr_val = self.respond_to?(method_name) ?
          self.send(method_name, obj) :
          obj.send(method_name)

        __assign_attribute(k, (attr_val || default_val))
      end
    end

    def valid?
      @valid ||= __schema__validate
    end

    def method_missing(mname, value=nil)
      if mname.to_s.end_with?('=')
        __assign_attribute(mname[0..-2].to_sym, value)
      else
        raise NoAttributeError.new(mname) unless @attributes.include?(mname.to_sym)

        @attributes[mname.to_sym]
      end
    end

    def get_value(k)
      @attributes[k.to_sym]
    end

    protected

    def __schema__validate
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
          @errors << e
        else
          @errors << m unless result
        end
      end
      @valid = (@errors.size == 0)
    end

    def __assign_attribute(name, value)
      raise NoAttributeError unless @attributes.include?(name)

      attr = self.class.schema_attributes[name]
      value = attr.type.new(value) if attr.type <= BaseSchema

      @valid = nil # a value is dirty so not valid anymore until next validation
      @attributes[name] = value
    end

  end
end
