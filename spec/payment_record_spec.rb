require 'spec_helper'

module JyskeBankRecord
  describe PaymentRecord do
    VALID_RECIPIENT = Recipient.new(
        '6666',
        '9876543210',
        name: 'nævn 1',
        address: 'modtager-adresse-1',
        address2: 'modtager-adresse-2',
        zip_code: '5000',
        city: 'Odense',
    ).freeze

    it 'should produce 9 notice chunks' do
      record = PaymentRecord.new(
          Date.new(2015, 9, 25),
          747,
          '123456789',
          VALID_RECIPIENT,
          entry_text: 'posteringstekst 1',
          reference: 'reference',
          notice: 'notice'
      )

      chunks = record.notice_chunks

      expect(chunks.length).to eq(9)
      expect(chunks).to eq(['notice'] + (Array.new(8) { '' }))
    end

    it 'should write to a 896 byte record' do
      record = PaymentRecord.new(
          Date.new(2015, 9, 25),
          747,
          '123456789',
          VALID_RECIPIENT,
          entry_text: 'posteringstekst 1',
          reference: 'reference',
          notice: 'notice',
      )

      stream = JyskeBankRecord.stream_records([record])

      output = stream.string
      expect(output.length).to eq(896)
    end

    it 'should reject an amount, that is not a number' do
      record = PaymentRecord.new(
          Date.today,
          'fisk',
          '1' * 15,
          VALID_RECIPIENT
      )

      record.validate
      expect(record.errors[:amount].any?).to be(true)
      expect(record.invalid?).to be(true)
    end

    it 'should reject invalid account number' do
      record = PaymentRecord.new(
          Date.today,
          100,
          '1234',
          VALID_RECIPIENT,
      )

      record.validate
      expect(record.errors[:sender_account_number].any?).to eq(true), lambda { record.sender_account_number }
    end

    it 'should not accept large fields' do
      [:entry_text, :reference, :notice].each do |attr|
        record = PaymentRecord.new(
            Date.today,
            100,
            '1' * 15,
            VALID_RECIPIENT,
            attr => 'x' * 100,
        )

        record.validate
        expect(record.errors[attr].any?).to eq(true)
      end
    end

    it 'should only accept a notice with up to 9 lines' do
      record = PaymentRecord.new(
          Date.today,
          100,
          '1' * 15,
          VALID_RECIPIENT,
          notice: (Array.new(10) { '.' }).join("\n")
      )

      record.validate
      expect(record.errors[:notice].any?).to eq(true), lambda { record.notice }
    end

    it 'should only accept a notice with lines of length 35 or less' do
      record = PaymentRecord.new(
          Date.today,
          100,
          '1' * 15,
          VALID_RECIPIENT,
          notice: (Array.new(9) { '.' * 36 }).join("\n")
      )

      record.validate
      expect(record.errors[:notice].length).to eq(9), lambda { "Expected 9 notice line errors, got #{record.errors[:notice].length}: " + record.errors.full_messages.inspect }
    end
  end
end