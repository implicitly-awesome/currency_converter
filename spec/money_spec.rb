require 'spec_helper'

describe CurrencyConverter::Money do

  let(:money) { described_class.new(123.4, 'QWE') }

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

  describe '.new' do

    it 'creates an instance with provided amount' do
      expect(money.amount).to eq(123.4)
    end

    it 'creates an instance with provided currency' do
      expect(money.currency).to eq('QWE')
    end
  end

  describe '#inspect' do

    it 'returns human representation' do
      expect(money.inspect).to eq("#{money.amount} #{money.currency}")
    end
  end

  describe '#to_s' do

    it 'returns human representation' do
      expect(money.to_s).to eq("#{money.amount} #{money.currency}")
    end
  end
end
