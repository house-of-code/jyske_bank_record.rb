module JyskeBankRecord
  DATE_FORMAT = "%Y%m%d"

  module Type
    PAYMENT_START = 'IB000000000000'
    PAYMENT_END = 'IB999999999999'
    DOMESTIC_RECORD = 'IB030202000005'
  end

  module AccountType
    FINANCIAL = '1'
    BANK = '2'
  end

  module Currency
    DKK = 'DKK'
  end

  module PaymentType
    CHEQUE = '1'
    TRANSFER = '2'
  end

  module NoticeType
    ATTACHED = '0'
    SEPARATE = '1'
    CHEQUE = '2'
  end

  module Record
    NEWLINE = "\r\n"

    def self.stream_records(records)
      return if records.empty?

      stream = StringIO.new

      # Set stream output to cp1252
      stream.set_encoding(Encoding::CP1252)

      records.each do |r|
        r.write(stream)
        stream << NEWLINE
      end

      stream
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

    Recipient = Struct.new(:registration_number, :account_number, :name, :address, :address2, :zip_code, :city) do
      def encode(encoding)
        each_pair do |key, value|
          if value.respond_to?(:encode)
            self[key] = value.encode(encoding)
          end
        end
      end
    end

    PaymentRecord = Struct.new(:processing_date, :amount, :sender_account_number, :recipient, :entry_text, :reference, :notice) do
      def fields
        start_fields = [
            Type::DOMESTIC_RECORD,
            '0001',
            processing_date.strftime(DATE_FORMAT),
            amount.abs.to_s.rjust(13, '0') + (amount && '+' || '-'),
            Currency::DKK,
            AccountType::BANK,
            sender_account_number.rjust(15, '0'), # sender account number
            PaymentType::TRANSFER,
            recipient.registration_number,
            recipient.account_number,
            NoticeType::ATTACHED,
            entry_text.ljust(35),
            recipient.name.ljust(32),
            recipient.address.ljust(32),
            recipient.address2.ljust(32),
            recipient.zip_code,
            recipient.city.ljust(32),
            reference.ljust(35),
        ]
        end_fields = [
            ' ',
            ' ' * 215
        ]

        start_fields + notice_chunks.map { |c| c.ljust(35) } + end_fields
      end

      # Chunk notice over
      def notice_chunks
        # Split to lines
        notice_lines = notice.strip().gsub("\r", '').split("\n")
        notice_lines.flat_map do |line|
          encoding = Encoding::CP1252
          line = line.encode(encoding)

          # Chunk to 35 chars
          arr = []
          until line.empty?
            arr << line.slice!(0..34)
          end
          arr
        end

        if notice_lines.length < 9
          notice_lines = notice_lines + (Array.new(9-notice_lines.length) { '' })
        end
        notice_lines
      end

      def write(stream)
        # Encode fields
        each_pair do |key, value|
          if value.respond_to?(:encode)
            self[key] = value.encode(Encoding::CP1252)
          end
        end

        recipient.encode(Encoding::CP1252)

        Record.write_fields(stream, fields)
      end
    end

  end
end
