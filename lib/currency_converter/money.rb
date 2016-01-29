module CurrencyConverter
  class Money
    include ::Comparable

    ##
    # Represents a configuration object of the Money class
    #
    class Configuration
      attr_accessor :base_currency, :rates

      def initialize(base_currency, rates)
        raise ArgumentError.new('Should provide base currency') unless base_currency
        @base_currency = base_currency.to_s
        @rates = rates.each_with_object({}) { |(k, v), new_hash| new_hash[k.to_s] = v.to_f }
      end
    end

    class << self
      attr_reader :configuration
    end

    ##
    # Configures Money. Sets conversion rates
    #
    # @param [String|Symbol] base_currency the base conversion currency
    # @param [Hash] rates currencies conversion rates relative base currency
    #
    def self.conversion_rates(base_currency, rates={})
      @configuration = Configuration.new(base_currency, rates)
      self
    end

    attr_reader :amount, :currency

    ##
    # @param [Integer|Float] amount amount of money
    # @param [String|Symbol] currency money currency
    #
    def initialize(amount, currency)
      raise_unknown_currency unless known_currency?(currency)
      
      @amount = amount.to_f.round(2)
      @currency = currency.to_s
    end

    ##
    # Converts Money object to another currency
    #
    # @param [String|Symbol] currency_name destination currency name
    #
    def convert_to(currency_name)
      raise_unknown_currency unless known_currency?(currency_name)

      return self if currency_name.to_s == currency

      converted_amount = convert_amount_to(currency_name)
      self.class.new(converted_amount, currency_name)
    end

    def inspect
      "#{'%.2f' % amount} #{currency}"
    end

    def to_s
      inspect
    end

    def +(object)
      do_arithmetic_with(object, :+)
    end

    def -(object)
      do_arithmetic_with(object, :-)
    end

    def /(object)
      do_arithmetic_with(object, :/)
    end

    def *(object)
      do_arithmetic_with(object, :*)
    end

    # need to implement in order to use ::Comparable module
    def <=>(compared_object)
      return nil unless compared_object.is_a?(CurrencyConverter::Money)

      amount <=> compared_object.convert_to(self.currency).amount
    end

    private

    ##
    # Converts money amount to amount in another currency
    #
    # @param [String|Symbol] to_currency a goal currency name
    #
    def convert_amount_to(to_currency)
      config = self.class.configuration

      if self.currency == config.base_currency
        self.amount * config.rates[to_currency.to_s]
      else
        if to_currency.to_s == config.base_currency
          self.amount / config.rates[self.currency]
        else
          self.amount / config.rates[self.currency] * config.rates[to_currency.to_s]
        end
      end
    end

    ##
    # Checks whether provided currency was registered in  Money configuration
    #
    # @param [String|Symbol] currency checked currency name
    #
    def known_currency?(currency)
      config = self.class.configuration
      config.base_currency == currency.to_s || config.rates.keys.include?(currency.to_s)
    end

    def raise_unknown_currency
      raise ArgumentError.new('Unknown currency. Please, configure via .conversion_rates')
    end

    ##
    # Invoke an arithmetic action (method) on money with provided object
    #
    # @param [Object] object an object participated in action
    # @param [String|Symbol] action_name an action which should be invoked on object
    #
    def do_arithmetic_with(object, action_name)
      first_amount = self.amount
      second_amount = if object.is_a?(CurrencyConverter::Money)
        object.convert_to(self.currency).amount
      else
        object.to_f rescue raise TypeError.new("Can't convert #{object.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
      end

      self.class.new(first_amount.send(action_name, second_amount), self.currency)
    end
  end
end