require 'spec_helper'

describe Erlen::Schema::AnyOf do
  subject { described_class }
  let(:any_of_1) { subject.new(TestAnyASchema, TestAnyBSchema) }
  let(:any_of_2) { subject.new(TestAnyASchema, TestAnyBSchema) }

  describe '#==' do
    it 'is equal to another of the same class and data' do
      payload1 = any_of_1.import(foo: 'bar', custom: 'v1')
      payload2 = any_of_1.import(foo: 'bar', custom: 'v1')

      expect(payload1 == payload2).to be(true)
    end

    it 'is equal to another AnyOf of the same class and data' do
      payload1 = any_of_1.import(foo: 'bar', custom: 'v1')
      payload2 = any_of_2.import(foo: 'bar', custom: 'v1')

      expect(payload1 == payload2).to be(true)
    end

    it 'is equal to another of the same concrete schema and data' do
      payload1 = any_of_1.import(foo: 'bar', custom: 'v1')
      payload2 = TestAnyASchema.import(foo: 'bar', custom: 'v1')

      expect(payload1 == payload2).to be(true)
      expect(payload2 == payload1).to be(true)
    end

    it 'is not equal to another if they differ in data' do
      payload1 = any_of_1.import(foo: 'bar', custom: 'v1')
      payload2 = any_of_1.import(foo: 'bar', custom: 'v2')

      expect(payload1 == payload2).to be(false)
    end

    it 'is not equal to another if they differ in class' do
      payload1 = any_of_1.import(foo: 'bar', custom: 'v1')
      payload2 = any_of_1.import(bar: 1, buzz: 'world')

      expect(payload1 == payload2).to be(false)
    end
  end
end

class TestAnyASchema < Erlen::Schema::Base
  attribute :foo, String
  attribute :custom, String
end

class TestAnyBSchema < Erlen::Schema::Base
  attribute :bar, Integer
  attribute :buzz, String
end
