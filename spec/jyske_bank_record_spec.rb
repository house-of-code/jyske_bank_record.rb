require 'spec_helper'

module JyskeBankRecord
  describe JyskeBankRecord do
    it 'should exist' do
      expect { PaymentStartRecord }.not_to raise_error
    end

    it 'should have records' do
      expect { PaymentStartRecord.new(Date.today) }.not_to raise_error
    end

    it 'should write records to a stream' do
      record = PaymentStartRecord.new(Date.new(2015, 8, 13))

      stream = StringIO.new
      record.write(stream)

      expect(stream.string).to match(/"20150813"/)
    end

    it 'a stream with encoding should output an encoded string' do
      stream = StringIO.new

      stream.set_encoding(Encoding::CP1252)

      stream << 'tæst'

      str = stream.string

      expect(str.length).to eq("t\xe6st".length)
      expect("t\xe6st").to eq("t\xe6st")
      expect(str.bytes).to eq("t\xe6st".bytes)
      expect(str).to eq('tæst'.encode(Encoding::CP1252))
    end

    it 'should write a bank record file' do
      date = Date.new(2015, 9, 17)
      start_record = PaymentStartRecord.new date
      end_record = PaymentEndRecord.new date, []

      records = [start_record, end_record]

      stream = JyskeBankRecord.stream_records(records)

      File.open(File.join(__dir__, "files", "empty")) do |f|
        left = stream.string
        right = f.read
        expect(left.length).to eq(right.length)
        expect(left).to eq(right)
      end
    end

    it 'should stream a bank record file with transactions' do
      date = Date.new(2015, 9, 17)
      start_record = PaymentStartRecord.new date

      transactions = [
        PaymentRecord.new(
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
            entry_text: 'posteringstekst 1',
            reference: 'eget bilags-nr',
            notice: (1..9).map{ |n| "advisering #{n}" }.join("\n")
        ),
        PaymentRecord.new(
            Date.new(2015, 9, 25),
            566,
            '1234567890',
            Recipient.new(
                '7777',
                '0123456789',
                name: 'navn 2',
                address: 'modtager-adresse-1-2',
                address2: 'modtager-adresse-2-2',
                zip_code: '6000',
                city: 'Kolding',
            ),
            entry_text: 'posteringstekst 2',
            reference: 'eget bilags-nr 2',
            notice: ''
        ),
      ]

      end_record = PaymentEndRecord.new date, transactions

      records = [start_record] + transactions + [end_record]

      File.open(File.join(__dir__, "files", "2_records"), encoding: Encoding::CP1252) do |f|
        left = JyskeBankRecord.format_records(records)
        right = f.read
        expect(left.length).to eq(right.length)
        expect(left).to eq(right)
      end
    end
  end
end
