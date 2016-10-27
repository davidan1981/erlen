require 'spec_helper'

describe Erlen::BaseSerializer do
  subject { described_class }

  describe "#data_to_schema" do
    it "sets all the values" do
      data = { foo: 'bar' }
      schema = subject.data_to_schema(data, TestBaseSerializerSchema)

      expect(schema.is_a? TestBaseSerializerSchema).to be_truthy
      expect(schema.foo).to eq('bar')
      expect(schema.valid?).to be_truthy
    end
  end

  describe "#schema_to_data" do
    it "returns hash of schema data" do
      schema =  TestBaseSerializerSchema.new({ foo: 'bar' })
      data = subject.schema_to_data(schema)

      expect(data).to include('foo')
      expect(data['foo']).to eq('bar')
    end
  end
end

class TestBaseSerializerSchema < Erlen::BaseSchema
  attribute :foo, String

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end
