require 'spec_helper'
require 'net/http'

module JyskeBankRecord
  module Record
    describe JyskeBankRecord::Record do
      it "should exist" do
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
        expect(str).to eq("tæst".encode(Encoding::CP1252))
      end

      it 'should write a bank record file' do
        date = Date.new(2015, 9, 17)
        start_record = PaymentStartRecord.new date
        end_record = PaymentEndRecord.new date, []

        records = [start_record, end_record]

        stream = Record.stream_records(records)

        File.open(File.join(__dir__, "files", "empty")) do |f|
          left = stream.string
          right = f.read
          expect(left.length).to eq(right.length)
          expect(left).to eq(right)
        end
      end

      it 'should write a bank record file with transactions' do
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
                'nævn 1',
                'modtager-adresse-1',
                'modtager-adresse-2',
                '5000',
                'Odense',
              ),
              'posteringstekst 1',
              'eget bilags-nr',
              (1..9).map{ |n| "advisering #{n}" }.join("\n")
          ),
          PaymentRecord.new(
              Date.new(2015, 9, 25),
              566,
              '1234567890',
              Recipient.new(
                  '7777',
                  '0123456789',
                  'navn 2',
                  'modtager-adresse-1-2',
                  'modtager-adresse-2-2',
                  '6000',
                  'Kolding',
              ),
              'posteringstekst 2',
              'eget bilags-nr 2',
              ''
          ),
        ]

        end_record = PaymentEndRecord.new date, transactions

        records = [start_record] + transactions + [end_record]

        stream = Record.stream_records(records)

        File.open(File.join(__dir__, "files", "2_records"), encoding: Encoding::CP1252) do |f|
          left = stream.string
          right = f.read
          expect(left.length).to eq(right.length)
          expect(left).to eq(right)
        end
      end

      describe PaymentRecord do
        it 'should 9 produce notice chunks' do
          record = PaymentRecord.new(
              Date.new(2015, 9, 25),
              747,
              '123456789',
              Recipient.new(
                  '6666',
                  '9876543210',
                  'nævn 1',
                  'modtager-adresse-1',
                  'modtager-adresse-2',
                  '5000',
                  'Odense',
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
                  'nævn 1',
                  'modtager-adresse-1',
                  'modtager-adresse-2',
                  '5000',
                  'Odense',
              ),
              'posteringstekst 1',
              'reference',
              'notice'
          )

          stream = Record.stream_records([record])

          output = stream.string
          expect(output.length).to eq(896)
        end
      end
    end
  end
end
