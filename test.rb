require_relative 'lib/erlen'

class PaymentMethodSchema < Erlen::BaseSchema
end

class AccountSchema < Erlen::BaseIDSchema
  attribute(:auto_pay, Boolean) {|value| true }
  attribute(:default_payment_method, PaymentMethodSchema, required: true)
  validate("Auto pay required") {|obj| obj.auto_pay == true}
end

now = Time.now
schema_obj = AccountSchema.new(created_at: now, updated_at: now)
another_schema_obj = AccountSchema.new
raise StandardError if schema_obj.created_at != now
raise StandardError if schema_obj.updated_at != now
schema_obj.auto_pay = 1
raise StandardError if schema_obj.valid?
schema_obj.auto_pay = false
raise StandardError unless schema_obj.auto_pay == false
raise StandardError if schema_obj.valid?

schema_obj.default_payment_method = PaymentMethodSchema.new
raise StandardError if schema_obj.valid?

schema_obj.auto_pay = true
schema_obj.valid?
puts(schema_obj.errors.map(){|e| e.message}.join("\n"))
raise StandardError unless schema_obj.valid?

raise StandardError if another_schema_obj.valid?
