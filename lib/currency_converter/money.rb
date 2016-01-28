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
      self
    end

    attr_reader :amount, :currency

    def initialize(amount, currency)
      raise_unknown_currency unless known_currency?(currency)
      @amount = amount.to_f.round(2)
      @currency = currency
    end

    def inspect
      "#{'%.2f' % amount} #{currency}"
    end

    def to_s
      inspect
    end

    def convert_to(currency_name)
      raise_unknown_currency unless known_currency?(currency_name)

      return self if currency_name == currency

      converted_amount = convert_amount_to(currency_name)
      self.class.new(converted_amount, currency_name)
    end

    private

    def known_currency?(currency)
      config = self.class.configuration
      config.base_currency == currency || config.rates.keys.include?(currency)
    end

    def raise_unknown_currency
      raise ArgumentError.new('Unknown currency. Please configure via .conversion_rates')
    end

    def convert_amount_to(to_currency)
      config = self.class.configuration

      if self.currency == config.base_currency
        self.amount * config.rates[to_currency]
      else
        if to_currency == config.base_currency
          self.amount / config.rates[self.currency]
        else
          self.amount / config.rates[self.currency] * config.rates[to_currency]
        end
      end
    end
  end
end