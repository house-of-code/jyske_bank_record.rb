# Hello
module JyskeBankRecord
  DATE_FORMAT = "%Y%m%d"
  module Type
    PAYMENT_START = 'IB000000000000'
    PAYMENT_END = 'IB999999999999'
  end
  module Record
    NEWLINE = "\r\n"

    def self.write_records(stream, records)
      return if records.empty?

      records.each do |r|
        r.write(stream)
        stream << NEWLINE
      end
    end

    def self.write_fields(stream, fields)
      return if fields.empty?
      stream << '"'
      stream << fields.first
      stream << '"'

      fields.drop(1).each do |f|
        stream << ','
        stream << '"'
        stream << f
        stream << '"'
      end
    end

    PaymentStartRecord = Struct.new(:creation_date) do
      def fields
        [
          'IB000000000000',
          creation_date.strftime(DATE_FORMAT),
          ' ' * 90,
          ' ' * 255,
          ' ' * 255,
          ' ' * 255,
        ]
      end

      def write(stream)
        Record.write_fields(stream, fields)
      end
    end

    PaymentEndRecord = Struct.new(:creation_date, :transactions) do
      def fields
        [
          'IB999999999999',
          creation_date.strftime(DATE_FORMAT),
          transactions.length.to_s.rjust(6, '0'),
          transactions.map(&:amount).reduce(:+).to_s.rjust(13, '0') + '+',
          ' ' * 64,
          ' ' * 255,
          ' ' * 255,
          ' ' * 255,
        ]
      end

      def write(stream)
        Record.write_fields(stream, fields)
      end
    end
  end
end
