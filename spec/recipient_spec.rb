require 'spec_helper'

module JyskeBankRecord
  describe Recipient do
    VALID_REGISTRATION_NUMBER = '1234'
    VALID_ACCOUNT_NUMBER = '0123456789'
    VALID_ARGUMENTS = {
        name: 'n' * 32,
        address: 'a' * 32,
        address2: 'a2' * 16,
        zip_code: 'z' * 4,
        city: 'c' * 32,
    }.freeze

    it 'should not accept invalid account number and registration number' do
      r = Recipient.new('', '123')

      r.validate
      expect(r.errors.full_messages.length).to eq(2)
    end

    it 'should accept valid inputs' do
      r = Recipient.new(VALID_REGISTRATION_NUMBER, VALID_ACCOUNT_NUMBER, **VALID_ARGUMENTS)

      expect(r.valid?).to eq(true), lambda { r.errors.full_messages.inspect }
    end

    it 'should not accept large inputs' do
      VALID_ARGUMENTS.each_key do |key|
        args = VALID_ARGUMENTS.merge(key => 'x' * 100)
        r = Recipient.new(VALID_REGISTRATION_NUMBER, VALID_ACCOUNT_NUMBER, **args)
        expect(r.valid?).to eq(false), lambda { r.to_yaml }
      end
    end
  end
end