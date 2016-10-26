require 'spec_helper'

describe Erlen::Attribute do
  subject { described_class }

  describe "#initialize" do
    it "sets all the values" do
      attr = subject.new(:name, Type, { foo: :bar }) { |s| "Block: #{s}" }

      expect(attr.name).to eq("name")
      expect(attr.type).to eq(Type)
      expect(attr.options).to eq({ foo: :bar })
      expect(attr.validation.call(1)).to eq("Block: 1")
    end

  end

  describe "#validate" do
    it "throws exception if is required, but is Undefined" do
      attr = subject.new(:required, Type, { required: true })

      expect { attr.validate(Erlen::Undefined.new) }.to raise_error(Erlen::ValidationError, "required is required")
    end

    it "if not required, but undefined. no checks" do
      attr = subject.new(:not_required, Type)
      attr.validate(Erlen::Undefined.new)
    end

    it "validates boolean" do
      attr = subject.new(:boolean, Boolean)

      expect { attr.validate(1) }.to raise_error(Erlen::ValidationError, "boolean: 1 is not Boolean")
      attr.validate(true)
    end

    it "validates nested schemas" do
      attr = subject.new(:nested, NestedSchema)

      hash = {}
      hash[:integer] = 1
      val = NestedSchema.new(hash)
      attr.validate(val)
    end

    it "validates type correctly" do
      attr = subject.new(:type, Type)
      attr.validate(Type.new)

      attr = subject.new(:number, Integer)
      attr.validate(1)
    end

    it "runs validation" do
      attr = subject.new(:type, Integer) { |t| raise "VALIDATION ERROR: #{t}" }

      expect { attr.validate(1) }.to raise_error("VALIDATION ERROR: 1")
    end

  end
end

class Type; end

class NestedSchema < Erlen::BaseSchema
  attribute :integer, Integer
end
