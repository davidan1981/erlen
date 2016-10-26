require 'spec_helper'

describe Erlen::BaseSchema do
  subject { described_class }

  describe "#initialize" do
    it "sets all the values" do
      schema = TestBaseSchema.new({ foo: 'bar' })

      expect(schema.class.schema_attributes).to include(:foo)
      expect(schema.foo).to eq('bar')
    end
  end

  describe "#valid?" do
    it "returns valid only if schema is perfect" do
      valid = TestBaseSchema.new({ foo: 'bar' })
      expect(valid.valid?).to be_truthy

      valid = TestBaseSchema.new({ foo: 1 })
      expect(valid.valid?).to be_falsey
    end
  end

  describe "#method_missing" do
    it "sets and gets attribute by method" do
      missing = TestBaseSchema.new({ foo: 'NOT' })
      expect(missing.valid?).to be_falsey
      expect(missing.foo).to eq('NOT')

      missing.foo = 'bar'
      expect(missing.valid?).to be_truthy
      expect(missing.foo).to eq('bar')
    end
  end

  describe "#errors" do
    it "compiles errors of everything wrong" do
      errors = TestBaseSchema.new({ foo: 13 })
      errors.valid?
      expect(errors.errors).to eq(["foo: 13 is not String", "Error Message"])
    end
  end

end

class TestBaseSchema < Erlen::BaseSchema
  attribute :foo, String

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end
