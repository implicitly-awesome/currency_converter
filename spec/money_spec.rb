require 'spec_helper'

describe CurrencyConverter::Money do

  describe '.conversion_rates' do

    context 'if base currency was not provided' do
      it 'raises an error' do
        expect { described_class.conversion_rates }.to raise_error(ArgumentError)
      end
    end

    it 'allows to define conversion rates' do
      described_class.conversion_rates('EUR', {'USD' => 1.11, 'Bitcoin' => 0.0047})
      expect(described_class.configuration.base_currency).to eq('EUR')
      expect(described_class.configuration.rates).to eq({'USD' => 1.11, 'Bitcoin' => 0.0047})
    end

    it 'stringify base currency' do
      described_class.conversion_rates(:EuR)
      expect(described_class.configuration.base_currency).to eq('EuR')
    end

    it 'stringify currency names in rates' do
      described_class.conversion_rates('EUR', {usd: 1.11})
      expect(described_class.configuration.rates['usd']).to eq(1.11)
    end
  end
end
