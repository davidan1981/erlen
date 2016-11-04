require 'spec_helper'

describe Erlen::EmptySchema do
  subject { described_class }

  class TestEmptySchema < Erlen::BaseSchema
    attribute :empty, Erlen::EmptySchema
  end

  class NotEmptySchema < Erlen::BaseSchema
    attribute :blah, String, required: true
  end

  describe "validate" do
    it "validates empty object" do
      empty = Erlen::EmptySchema.new
      expect(empty.valid?).to be_truthy
      test = TestEmptySchema.new(empty: empty)
      expect(test.valid?).to be_truthy
      not_empty = NotEmptySchema.new(blah: "blah")
      expect(not_empty.valid?).to be_truthy
      test = TestEmptySchema.new(empty: not_empty)
      expect(test.valid?).to be_falsey
    end
  end
end

describe Erlen::AnySchema do
  subject { described_class }

  class SomeSchema < Erlen::BaseSchema
    attribute :flag, Boolean, required: true
  end

  describe "validate" do
    it "validates some payload as any schema payload" do
      some = SomeSchema.new(flag: true)
      expect(some.valid?).to be_truthy
      any = Erlen::AnySchema.new(some)
      expect(any.valid?).to be_truthy
    end
  end
end

describe Erlen::AnyOf do
  subject { described_class }

  class Dog < Erlen::BaseSchema
    attribute :woof, Boolean, required: true
  end

  class Cat < Erlen::BaseSchema
    attribute :meow, Boolean, required: true
  end

  class Cow < Erlen::BaseSchema
    attribute :moo, Boolean, required: true
  end

  DogOrCat = Erlen::AnyOf.new(Dog, Cat)
  CowOrNothing = Erlen::AnyOf.new(Cow, Erlen::EmptySchema)

  describe "validate" do
    it "validates as long as one schema matches" do
      dog = Dog.new(woof: true)
      expect(dog.valid?).to be_truthy
      dog_or_cat = DogOrCat.new(dog)
      expect(dog_or_cat.is_a? Dog).to be_truthy
      expect(dog_or_cat.is_a? Cat).to be_truthy
      expect(dog_or_cat.is_a? Cow).to be_falsey
      expect(dog_or_cat.valid?).to be_truthy
      cow = Cow.new(moo: true)
      dog_or_cat = DogOrCat.new(cow)
      expect(dog_or_cat.valid?).to be_falsey
    end
    it "validates optional schema" do
      cow_or_nothing = CowOrNothing.new({})
      expect(cow_or_nothing).to be_truthy
      cow = Cow.new(moo: true)
      cow_or_nothing = CowOrNothing.new(cow)
      expect(cow_or_nothing.valid?).to be_truthy
      cow_or_nothing = CowOrNothing.new(woof: true)
      expect(cow_or_nothing.valid?).to be_falsey
    end
  end
end

describe Erlen::ArrayOf do
  subject { described_class }

  class Apple < Erlen::BaseSchema
    attribute :poisonous, Boolean
  end

  class Pear < Erlen::BaseSchema
    attribute :sweet, Boolean
  end

  BasketOfApples = Erlen::ArrayOf.new(Apple)

  describe "validate" do
    it "validates apple and not pear" do
      apple = Apple.new(poisonous: true)
      expect(apple.valid?).to be_truthy
      basket = BasketOfApples.new
      basket.elements << apple
      expect(basket.valid?).to be_truthy
      basket.elements << apple
      expect(basket.valid?).to be_truthy
      pear = Pear.new(sweet: false)
      basket.elements << pear
      expect(basket.valid?).to be_falsey
      basket.elements.pop
      expect(basket.valid?).to be_truthy
    end
  end

end
