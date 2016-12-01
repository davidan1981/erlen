[![Build Status](https://travis-ci.org/Hireology/erlen.svg?branch=master)](https://travis-ci.org/Hireology/erlen)
[![Coverage Status](https://coveralls.io/repos/github/Hireology/erlen/badge.svg?branch=master)](https://coveralls.io/github/Hireology/erlen)

# Erlen

Erlen is short for
[Erlenmeyer](https://en.wikipedia.org/wiki/Erlenmeyer_flask), a type of
laboratory flask that looks like Hireology's logo. Erlen is a Ruby library
that provides a framework for schema creation, validation, and
serialization. A schema is a definition of a resource or a resource group
and describes what is expected in a transaction regardless of the
protocol--e.g., HTTP, RPC, Ruby call, and etc.  In other words, Erlen allows
you to define contracts and share them across different services and also
enforce what is defined in the contracts.

## Installation

TBD

## Definitions

For convenience, let's define a few terms we will be using throughout this
documentation.

### Schema

A formal contract between two or more parties, defined with a set of of
attributes and validations. It is represented as a class which inherits from
`Erlen::Schema::Base`. Note that a schema is a _portable_ definition so
there is no business logic embedded within a schema.

### Attribute

A property defined in a schema. Zero or more attributes can be defined in a
schema. An attribute is defined with a unique name, a type, and various
options.

### Payload

Also called a _schema object_. An instance of `Erlen::Schema::Base` or its
descendent with actual data.

## Usage

It's easy to use Erlen. In a typical Rails application, you will define a
set of schemas and configure controllers to specify action and schema
associations. Let's look at how one can define a schema.

In order to define a schema, just create a class that inherits from
`Erlen::Schema::Base` or any of its descendents. For example, a user schema
can be defined as the following:

    class UserSchema < Erlen::Schema::Base
      attribute :name, String, required: true { |a| a.length > 5 }
      attribute :email, String, required: true
      attribute :nickname, String, required: false
      attribute :organization, OrganizationSchema, required: true
      validate { |payload| payload.name != payload.email }
    end

### Attribute

An attribute can be defined with a name, a type, various options, and
an attribute-specific validation. The name and type must be specified.
A type can be either a primitive Ruby type or a schema.

Here are primitive types that are supported:

* String
* Numberic (Float, Integer, and etc.)
* Boolean (TrueClass, FalseClass)
* DateTime

Note that their subclasses are also supported whereas schema types must
match exactly. (More explained later.)

Currently, options include

* required: this option flag makes the attribute a required attribute for
  the schema. By default, this option is set to false.
* alias: this option allows schema to also look into alias for importing
  or initialialization.
* default: if this option is specified, the value will be used as a default
  value if the corresponding attribute value is missing from the source
  data.

A validation block can be specified to perform an attribute-specific
validation (as opposed to schema-wide validation).

### Validation

A schema can have zero or more custom validation code. Each validation is
represented with a code block, and the payload is passed in as the block
argument.

For example,

      validate { |payload| payload.name != payload.nickname }

ensures that the payload's name and nickname do not match.

### Instantiation

By instantiating the user schema, you get a user payload.

    user_payload = UserSchema.new(
        name: "Joe Smith",
        email: "joe@smith.com",
        organization: {
          id: 1,
          name: "Hireology"
        }
    )

For convenience, you may pass in a hash object from which attributes will be
assigned. If you are using this method, the initial object must be a hash
object that does not contain any attribute that is not defined in the
schema. Otherwise, an `Erlen::NoAttributeError` will be thrown.

### Importing

Alternatively, you may use `import` method instead:

    user_payload = UserSchema.import(user)

User can be _any_ object (including a payload) possibly with some attributes
populated. This method is more graceful than the former since any undefined
attributes from the source object will be simply ignored. It will be
particularly useful to import data from an active record object, for
example.

### Pre-defined Schemas

For your convenience, Erlen is shipped with pre-defined schemas (under
`Erlen::Schema` namespace):

* `Erlen::Schema::Empty` has nothing. It will only match empty payload.
* `Erlen::Schema::Any`  is a special schema definition that allows _any_
  payload. No validation will occur.
* `Erlen::Schema::Resource` represents a _resource_ payload, as defined in
  Hireology API Standards.

### Schema Generators

Erlen also includes a few schema generators. They are like functors (as in
OCaml) that dynamically generate classes based on additional type
information. Here is the list of schema generators:

* `Erlen::Schema::AnyOf` can generate a schema that can represent one or
  more schemas. The payload of the generated schema can be any of the
  specified schemas.
* `Erlen::Schema::ArrayOf` can generate a schema that contains multiple
  elements of the specified type (which can be either a primitive or
  schema).
* `Erlen::Schema::ResourceArrayOf`: Similar to `ArrayOf` but the generated
  schema has a resource list structure, as defined in Hireology API
  Standards.

For instance,

    AnyOf.new(DogSchema, CatSchema)

generates a schema whose payload can be either a dog or a cat.

Consider another example:

    ArrayOf.new(Integer)

This generates a schema that works as an array of `Integer`s. The generated
schema has a set of Array operators as well:

    ints = ArrayOf.new(Integer)
    ints << 1
    ints << 2
    x = ints[0] # 1

### ControllerHelper

Erlen is shipped with a Rails helper called `Erlen::Rails::ControllerHelper` which
can be included in a controller to associate actions with schemas.

    class UsersController < ApplicationConroller
      include Erlen::Rails::ControllerHelper

      action_schema :index, response: ResourceListOfUsersSchema
      action_schema :create, request: UserCreateRequestSchema, response: UserResponseSchema
      action_schema :update, request: UserUpdateRequestSchema, response: UserResponseSchema
      action_schema :show, response: UserResponseSchema

      def create
        # ...
      end

      def update
        # ...
      end

      def show
        # ...
      end

      def destroy
        # ...
      end

    end

It is important to note that the above example used slightly different
schemas for different actions and between requests and response. This is
typical because different actions and inputs/outputs require different set
of attributes, validations, and etc. We strongly recommend that schemas are
defined in a sense that they are highly resuable and composable because of
this reason.

The magical part of this is that once a schema is defined for an action, the
rest if automated. By defining a request schema, a callback is registered
before the specified action to validate the raw request body and hydrate the
data into a payload. By defining a response schema, another callback is
registered to perform a validation on the response body.

For your convenience, `Erlen::Rails::ControllerHelper` overloads `render`
method so you can easily render a payload.

    render(payload: user_payload, status: 200)

This is not required, however. The advantage of using the above method is
(1) you don't need to serialize the payload into JSON yourself, and (2)
validation is done at the time of `render` call, which is helpful for
debugging purpose.

Note that, if payload is rendered using the above form, the after action
callback will skip the validation (as long as there wasn't any other render
call.)

## License

Erlen is released under the MIT License:
www.opensource.org/licenses/MIT
