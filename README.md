# Erlen

Erlen is short for Erlenmeyer, a type of laboratory flask that looks like
Hireology's logo. Erlen is a library that provides a framework for schema
creation, validation, and serialization. A schema is a definition of a
resource or a resource group and describes what is expected in a transaction
regardless of the protocol--e.g., HTTP, RPC, Ruby call, and etc. In other
words, Erlen allows you to define contracts and share them across different
services and also enforce what is defined in the contracts.

## Installation

TBD

## Definitions

* Schema - a contract definition that includes a list of attributes and
validations. It is represented as a class which inherits from
`Erlen::BaseSchema`.
* Payload - an instance of Schema. It is an actual piece of data that has
been validated against its schema definition.

## Usage

TBA

## Pre-defined Schemas

For your convenience, we have defined a few schemas in the Erlen library.

* `EmptySchema`: there is nothing in this schema.
* `AnySchema`: this is a special schema definition that allows _any_
payload
* `ResourceSchema`: This schema represents a resource payload which includes
`id` and timestamp fields, `created_at` and `updated_at`.
* `OneOf`: This allows any payload whose schema is one of the specified.
* `ArrayOf`: This schema represents a list of payloads of the specified
type.
* `ResourceListOf`: Similar to `ArrayOf` but has a structure as defined in
our API standard.

## Advanced Topics

### Typing

TBD
