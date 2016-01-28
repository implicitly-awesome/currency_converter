require 'spec_helper'

describe CurrencyConverter::Money do

  BASE_CURRENCY = 'EUR'
  RATES = {'USD' => 1.11, 'Bitcoin' => 0.0047}
  UNKNOWN_CURRENCY = 'QWE'
  UNKNOWN_CURRENCY_ERROR_MESSAGE = 'Unknown currency. Please configure via .conversion_rates'

  before do
    described_class.conversion_rates(BASE_CURRENCY, RATES)
  end

  describe '.conversion_rates' do

    it 'allows to define conversion rates' do
      expect(described_class.configuration.base_currency).to eq(BASE_CURRENCY)
      expect(described_class.configuration.rates).to eq(RATES)
    end

    it 'returns configured class' do
      expect(described_class.conversion_rates(BASE_CURRENCY)).to eq(CurrencyConverter::Money)
    end

    it 'stringify base currency' do
      described_class.conversion_rates(:EuR)
      expect(described_class.configuration.base_currency).to eq('EuR')
    end

    it 'stringify currency names in rates' do
      described_class.conversion_rates(BASE_CURRENCY, {usd: 1.11})
      expect(described_class.configuration.rates['usd']).to eq(1.11)
    end
  end

  describe '.new' do

    it 'raises an error with unknown provided currency' do
      expect { described_class.new(123.4, UNKNOWN_CURRENCY) }.to raise_error(ArgumentError, UNKNOWN_CURRENCY_ERROR_MESSAGE)
    end

    it 'creates an instance with provided amount' do
      expect(described_class.new(123.4, BASE_CURRENCY).amount).to eq(123.4)
    end

    it 'cast amount to float' do
      expect(described_class.new(123, BASE_CURRENCY).amount).to be_a(Float)
    end

    it 'stores amount with precision = 2' do
      expect(described_class.new(123.456, BASE_CURRENCY).amount).to eq(123.46)
    end

    it 'creates an instance with provided currency' do
      expect(described_class.new(123.4, BASE_CURRENCY).currency).to eq(BASE_CURRENCY)
    end

  end

  let(:money) { described_class.new(50, BASE_CURRENCY) }

  describe '#inspect' do

    it 'returns human representation' do
      expect(money.inspect).to eq("#{'%.2f' % money.amount} #{money.currency}")
    end
  end

  describe '#to_s' do

    it 'returns human representation' do
      expect(money.to_s).to eq("#{'%.2f' % money.amount} #{money.currency}")
    end
  end

  describe '#convert_to' do

    it 'raises an error if unknown currency was provided' do
      expect { money.convert_to(UNKNOWN_CURRENCY) }.to raise_error(ArgumentError, UNKNOWN_CURRENCY_ERROR_MESSAGE)
    end

    it 'returns Money instance' do
      expect(money.convert_to('USD')).to be_a(described_class)
    end

    context 'while converting to a self currency' do

      it 'returns itself' do
        expect(money.convert_to(money.currency).__id__).to eq(money.__id__)
      end
    end

    context 'while converting to a different currency' do

      let(:converted_money) { money.convert_to('USD') }

      it 'returns a new instance' do
        expect(converted_money.__id__).not_to eq(money.__id__)
      end

      it 'returns instance with a different currency' do
        expect(converted_money.currency).to eq('USD')
      end

      context 'if current currency equals to base conversion currency' do

        it "returns amount multiplied by 'converted to' currency's rate" do
          expect(converted_money.amount).to eq(55.50)
        end
      end

      context 'if current currency differs from base conversion currency' do

        let(:money) { described_class.new(55.50, 'USD') }

        context 'if converted to base conversion currency' do

          it "returns amount devided by current currency's rate" do
            expect(money.convert_to(BASE_CURRENCY).amount).to eq(50.00)
          end
        end

        context 'if converted not to base conversion currency' do

          it "returns amount devided by current currency's rate and multiplied by 'converted to' currency's rate" do
            expect(money.convert_to('Bitcoin').amount).to eq(0.24)
          end
        end
      end
    end
  end
end
