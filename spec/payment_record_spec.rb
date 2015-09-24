require 'spec_helper'

module JyskeBankRecord
  describe PaymentRecord do
    it 'should produce 9 notice chunks' do
      record = PaymentRecord.new(
          Date.new(2015, 9, 25),
          747,
          '123456789',
          Recipient.new(
              '6666',
              '9876543210',
              name: 'nævn 1',
              address: 'modtager-adresse-1',
              address2: 'modtager-adresse-2',
              zip_code: '5000',
              city: 'Odense',
          ),
          'posteringstekst 1',
          'reference',
          'notice'
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
          Recipient.new(
              '6666',
              '9876543210',
              name: 'nævn 1',
              address: 'modtager-adresse-1',
              address2: 'modtager-adresse-2',
              zip_code: '5000',
              city: 'Odense',
          ),
          'posteringstekst 1',
          'reference',
          'notice'
      )

      stream = JyskeBankRecord.stream_records([record])

      output = stream.string
      expect(output.length).to eq(896)
    end

    it 'should write to a 896 byte record' do
      record = PaymentRecord.new(
          Date.new(2015, 9, 25),
          747,
          '123456789',
          Recipient.new(
              '6666',
              '9876543210',
              name: 'nævn 1',
              address: 'modtager-adresse-1',
              address2: 'modtager-adresse-2',
              zip_code: '5000',
              city: 'Odense',
          ),
          'posteringstekst 1',
          'reference',
          'notice'
      )

      stream = JyskeBankRecord.stream_records([record])

      output = stream.string
      expect(output.length).to eq(896)
    end
  end
end