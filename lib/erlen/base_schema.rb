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
        attr = Attribute.new(name.to_s, type, opts, &validation)
        schema_attributes[name.to_s] = attr
      end

      def validate(&blk)
        validator_procs << blk
      end
    end

    def initialize(attributes = {})
      @valid = nil
      @attributes = {}
      @errors = []

      # Initialize all values to undefined
      self.class.schema_attributes.each_pair do |k, v|
        @attributes[k] = Undefined.new
      end

      # Bulk assign initial attributes
      attributes.each_pair do |k, v|
        __assign_attribute(k, v)
      end
    end

    def valid?
      if @valid.nil?
        __schema__validate
      else
        @valid
      end
    end

    def method_missing(mname, value=nil)
      if mname.to_s.end_with?('=')
        __assign_attribute(mname.to_s[0..-2], value)
      else
        raise mname.inspect unless @attributes.include?(mname.to_s)

        @attributes[mname.to_s]
      end
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
      klass.validator_procs.each do |p|
        begin
          result = p.call(self)
        rescue Exception => e
          @errors << e
        else
          unless result
            file, line = p.source_location
            @errors << "Validation failed for #{file}:#{line}"
          end
        end
      end
      @valid = (@errors.size == 0)
    end

    def __assign_attribute(name, value)
      raise name.inspect unless @attributes.include?(name)

      attr = self.class.schema_attributes[name.to_s]
      value = attr.type.new(value) if attr.type <= BaseSchema

      @valid = nil # a value is dirty so not valid anymore until next validation
      @attributes[name] = value
    end

  end
end
