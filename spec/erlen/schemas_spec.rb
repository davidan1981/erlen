require 'spec_helper'

describe Erlen::OneOf do
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

  DogOrCat = Erlen::OneOf.new(Dog, Cat)

  describe "validate" do
    it "validates as long as one schema matches" do
      dog = Dog.new(woof: true)
      expect(dog.valid?).to be_truthy
      dog_or_cat = DogOrCat.new(dog)
      expect(dog_or_cat.is_a? Dog).to be_truthy
      expect(dog_or_cat.is_a? Cat).to be_truthy
      expect(dog_or_cat.is_a? Cow).to be_falsey
      dog_or_cat.valid?
      expect(dog_or_cat.valid?).to be_truthy
      cow = Cow.new(moo: true)
      dog_or_cat = DogOrCat.new(cow)
      expect(dog_or_cat.valid?).to be_falsey
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
