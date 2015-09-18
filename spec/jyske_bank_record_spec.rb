require 'spec_helper'
require 'net/http'

module JyskeBankRecord
  module Record
    describe JyskeBankRecord::Record do
      it "should exist" do
        expect { PaymentStartRecord }.not_to raise_error
      end

      it 'should have records' do
        record = PaymentStartRecord.new(Date.today)
      end

      it 'should write records to a stream' do
        record = PaymentStartRecord.new(Date.new(2015, 8, 13))

        stream = StringIO.new
        record.write(stream)

        expect(stream.string).to match(/"20150813"/)
      end

      it 'should write a bank record file' do
        stream = StringIO.new 

        date = Date.new(2015, 9, 17)
        start_record = PaymentStartRecord.new date
        end_record = PaymentEndRecord.new date, []

        records = [start_record, end_record]

        Record.write_records(stream, records)

        File.open(File.join(__dir__, "files", "empty")) do |f|
          left = stream.string
          right = f.read
          expect(left.length).to eq(right.length)
          expect(left).to eq(right)
        end
      end
    end
  end
end
