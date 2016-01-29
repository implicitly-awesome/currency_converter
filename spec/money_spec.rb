require 'spec_helper'

describe CurrencyConverter::Money do

  BASE_CURRENCY = 'EUR'
  RATES = {'USD' => 1.11, 'Bitcoin' => 0.0047}
  UNKNOWN_CURRENCY = 'QWE'

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
      expect { described_class.new(123.4, UNKNOWN_CURRENCY) }.to raise_error(ArgumentError, 'Unknown currency. Please, configure via .conversion_rates')
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
      expect { money.convert_to(UNKNOWN_CURRENCY) }.to raise_error(ArgumentError, 'Unknown currency. Please, configure via .conversion_rates')
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

  context 'arithmetics' do

    let(:left_money) { described_class.new(1.5, 'EUR') }
    let(:right_money) { described_class.new(1, 'USD') }

    describe 'method #+' do

      it 'returns an instance of Money' do
        result = left_money + right_money
        expect(result).to be_a(described_class)
      end

      it 'results currency equals to left money' do
        result = left_money + right_money
        expect(result.currency).to eq('EUR')
      end

      context 'if addend is a Money object' do

        it "converts right money's amount then sums up" do
          result = left_money + right_money
          expect(result.amount).to eq(2.40)
        end

        context 'if addends are in the same currency' do

          let(:right_money) { described_class.new(1, 'EUR') }

          it 'returns addition of two amounts' do
            result = left_money + right_money
            expect(result.amount).to eq(2.5)
          end
        end
      end

      context 'if addend is not a Money object' do

        it "converts addend to Float and sums up it with left money's amount" do
          result = left_money + 1
          expect(result.amount).to eq(2.5)
        end

        context 'if conversion failed' do

          it 'raises an error' do
            addend = [1]
            expect { left_money + addend }.to raise_error(TypeError, "Can't convert #{addend.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe 'method #-' do

      it 'returns an instance of Money' do
        result = left_money - right_money
        expect(result).to be_a(described_class)
      end

      it 'results currency equals to left money' do
        result = left_money - right_money
        expect(result.currency).to eq('EUR')
      end

      context 'if subtrahend is a Money object' do

        it "converts right money's amount then subtracts" do
          result = left_money - right_money
          expect(result.amount).to eq(0.6)
        end

        context 'if money are in the same currency' do

          let(:right_money) { described_class.new(1, 'EUR') }

          it 'returns subtraction of two amounts' do
            result = left_money - right_money
            expect(result.amount).to eq(0.5)
          end
        end
      end

      context 'if subtrahend is not a Money object' do

        it "converts subtrahend to Float and subtracts it from left money's amount" do
          result = left_money - 1
          expect(result.amount).to eq(0.5)
        end

        context 'if conversion failed' do

          it 'raises an error' do
            subtrahend = [1]
            expect { left_money - subtrahend }.to raise_error(TypeError, "Can't convert #{subtrahend.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe 'method #/' do

      it 'returns an instance of Money' do
        result = left_money / right_money
        expect(result).to be_a(described_class)
      end

      it 'results currency equals to left money' do
        result = left_money / right_money
        expect(result.currency).to eq('EUR')
      end

      context 'if divider is a Money object' do

        it "converts right money's amount then divide" do
          result = left_money / right_money
          expect(result.amount).to eq(1.67)
        end

        context 'if money are in the same currency' do

          let(:right_money) { described_class.new(0.5, 'EUR') }

          it 'returns division of two amounts' do
            result = left_money / right_money
            expect(result.amount).to eq(3.0)
          end
        end
      end

      context 'if divider is not a Money object' do

        it "converts divider to Float and divides left money's amount" do
          result = left_money / 2
          expect(result.amount).to eq(0.75)
        end

        context 'if conversion failed' do

          it 'raises an error' do
            divider = [1]
            expect { left_money / divider }.to raise_error(TypeError, "Can't convert #{divider.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe 'method #*' do

      it 'returns an instance of Money' do
        result = left_money * right_money
        expect(result).to be_a(described_class)
      end

      it 'results currency equals to left money' do
        result = left_money * right_money
        expect(result.currency).to eq('EUR')
      end

      context 'if multiplier is a Money object' do

        it "converts right money's amount then divide" do
          result = left_money * right_money
          expect(result.amount).to eq(1.35)
        end

        context 'if money are in the same currency' do

          let(:right_money) { described_class.new(0.5, 'EUR') }

          it 'returns multiplication of two amounts' do
            result = left_money * right_money
            expect(result.amount).to eq(0.75)
          end
        end
      end

      context 'if multiplier is not a Money object' do

        it "converts multiplier to Float and multiplies left money's amount" do
          result = left_money * 2
          expect(result.amount).to eq(3.0)
        end

        context 'if conversion failed' do

          it 'raises an error' do
            multiplier = [1]
            expect { left_money * multiplier }.to raise_error(TypeError, "Can't convert #{multiplier.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end
  end
end
