require 'spec_helper'

describe Erlen::JSONSerializer do
  subject { described_class }

  describe "#from_json" do
    it "sets all the values" do
      json = "{\"foo\":\"bar\"}"
      schema = subject.from_json(json, TestSerializerSchema)

      expect(schema.is_a? TestSerializerSchema).to be_truthy
      expect(schema.foo).to eq('bar')
      expect(schema.valid?).to be_truthy
    end
  end

  describe "#to_json" do
    it "returns json with right values" do
      json = "{\"foo\":\"bar\"}"
      schema = subject.from_json(json, TestSerializerSchema)

      expect(schema.is_a? TestSerializerSchema).to be_truthy
      expect(schema.foo).to eq('bar')
      expect(schema.valid?).to be_truthy
    end
  end
end

class TestSerializerSchema < Erlen::BaseSchema
  attribute :foo, String

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end

