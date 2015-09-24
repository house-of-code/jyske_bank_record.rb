require 'active_model'

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

  # Encode variables given binding and set as instance variables
  module EncodeCp1252AndSet
    # @param [Binding] _binding binding for getting value of instance variables
    # @param [Enumerable] names parameter names to encode and set
      def encode_and_set(_binding, names)
        names.each do |name|
          value = _binding.local_variable_get name
          instance_variable_set ('@' + name.to_s).to_sym, value.to_s.encode!(Encoding::CP1252)
        end
      end
  end

  NEWLINE = "\r\n"

  # Format a string of bank records, with correct encoding
  def self.format_records(records)
    return '' if records.empty?
    self.stream_records(records).string
  end

  # Produce a stream containing a formatted bank record file
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
      JyskeBankRecord.write_fields(stream, fields)
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
      JyskeBankRecord.write_fields(stream, fields)
    end
  end

  # Recipient = Struct.new(:registration_number, :account_number, :name, :address, :address2, :zip_code, :city)
  class Recipient
    include ActiveModel::Validations
    include JyskeBankRecord::EncodeCp1252AndSet

    @@parameters = [:registration_number, :account_number, :name, :address, :address2, :zip_code, :city]

    attr_reader *@@parameters

    validates_presence_of *@@parameters, {allow_blank: true, allow_nil: false}
    validates_length_of :registration_number, is: 4
    validates :account_number, presence: true, length: {is: 10}

    validates_length_of :name, :address, :address2, :city, {maximum: 32}
    validates_length_of :zip_code, maximum: 4

    # @param [String] registration_number 4 characters
    # @param [String] account_number 10 characters
    # @param [String] name
    # @param [String] address
    # @param [String] address2
    # @param [String] zip_code
    # @param [String] city
    def initialize(registration_number, account_number, name: '', address: '', address2: '', zip_code: '', city: '')

      # Encode and save parameters
      encode_and_set binding, @@parameters
    end
  end

  class PaymentRecord
    include ActiveModel::Validations
    include JyskeBankRecord::EncodeCp1252AndSet

    @@parameters = [:sender_account_number, :entry_text, :reference, :notice]

    attr_reader *@@parameters
    attr_reader :processing_date, :amount, :recipient

    validates_presence_of *@@parameters, {allow_blank: true, allow_nil: false}
    validates_each :processing_date do |record, attr, value|
      record.errors.add(attr, 'must respond to strftime') unless value.respond_to? :strftime
    end
    validates_numericality_of :amount
    validates_each :amount do |record, attr, value|
      record.errors.add(attr, 'must be a Fixnum') unless value.instance_of? Fixnum
    end
    validates_length_of :sender_account_number, is: 15
    validates_length_of :entry_text, :reference, maximum: 35

    # Validate notice for 9 lines, each less than or equal to 35 chars
    validates_each :notice do |record, attr, value|
      lines = value.lines
      record.errors.add(attr, 'must have a maximum of 9 lines') if lines.length > 9
      lines.each_with_index do |line, i|
        if line.length > 35
          record.errors.add(attr, "must have lines at most 35 (cp1252) chars of length, line #{i+1} is #{line.length} chars long")
        end
      end
    end

    def initialize(processing_date, amount, sender_account_number, recipient, entry_text: '', reference: '', notice: '')
      encode_and_set binding, @@parameters
      @processing_date = processing_date
      @amount = amount
      @recipient = recipient
    end

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
      JyskeBankRecord.write_fields(stream, fields)
    end
  end
end
