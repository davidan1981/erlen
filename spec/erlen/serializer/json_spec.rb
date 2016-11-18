require 'spec_helper'

describe Erlen::Serializer::JSON do
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
      s = TestSerializerSchema.new({ foo: 'bar' })

      expect(subject.to_json(s)).to eq(json)
    end
  end
end

class TestSerializerSchema < Erlen::Schema::Base
  attribute :foo, String

  validate("Error Message") { |s| s.foo == 'bar' || s.foo == 1 }
end

