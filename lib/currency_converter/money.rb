module CurrencyConverter
  class Money
    class Configuration
      attr_accessor :base_currency, :rates

      def initialize(base_currency, rates)
        raise ArgumentError.new('Should provide base currency') unless base_currency
        @base_currency = base_currency.to_s
        @rates = rates.each_with_object({}) { |(k, v), new_hash| new_hash[k.to_s] = v }
      end
    end

    class << self
      attr_reader :configuration
    end

    def self.conversion_rates(base_currency, rates={})
      @configuration = Configuration.new(base_currency, rates)
    end

    attr_reader :amount, :currency

    def initialize(amount, currency)
      @amount = amount
      @currency = currency
    end

  end
end