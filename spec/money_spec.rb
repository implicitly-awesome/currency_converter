require 'spec_helper'

describe CurrencyConverter::Money do

  BASE_CURRENCY = 'EUR'
  RATES = {'USD' => 1.11, 'Bitcoin' => 0.0047}

  describe '.conversion_rates' do
    before do
      described_class.conversion_rates(BASE_CURRENCY, RATES)
    end

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

    it 'converts currency rates to float in rates' do
      described_class.conversion_rates(BASE_CURRENCY, {usd: 12})
      expect(described_class.configuration.rates['usd']).to be_a(Float)
    end
  end

  describe '.new' do
    before do
      described_class.conversion_rates(BASE_CURRENCY, RATES)
    end

    it 'raises an error with unknown provided currency' do
      expect { described_class.new(123.4, 'QWE') }.to raise_error(ArgumentError, 'Unknown currency. Please, configure via .conversion_rates')
    end

    it 'creates an instance with provided amount' do
      expect(described_class.new(123.4, BASE_CURRENCY).amount).to eq(123.4)
    end

    it 'cast an amount to float' do
      expect(described_class.new(123, BASE_CURRENCY).amount).to be_a(Float)
    end

    it 'creates an instance with provided currency' do
      expect(described_class.new(123.4, BASE_CURRENCY).currency).to eq(BASE_CURRENCY)
    end
  end

  context 'instance methods' do
    let(:money) { described_class.new(50, BASE_CURRENCY) }

    before do
      described_class.conversion_rates(BASE_CURRENCY, RATES)
    end

    shared_examples_for 'money-creator method' do |method, *args|
      it 'returns an instance of Money' do
        expect(money.send(method, *args)).to be_a(described_class)
      end
    end

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
      it_behaves_like 'money-creator method', :convert_to, 'USD'

      it 'raises an error if unknown currency was provided' do
        expect { money.convert_to('QWE') }.to raise_error(ArgumentError, 'Unknown currency. Please, configure via .conversion_rates')
      end

      context 'while converting to a self currency' do
        it 'returns itself' do
          expect(money.convert_to(money.currency).__id__).to eq(money.__id__)
        end
      end

      context 'while converting to a different currency' do
        let(:converted_money) { money.convert_to('USD') }
        let(:money_config) { described_class.configuration }

        it 'returns a new instance' do
          expect(converted_money.__id__).not_to eq(money.__id__)
        end

        it 'returns instance with a different currency' do
          expect(converted_money.currency).to eq('USD')
        end

        context 'when current currency equals to base conversion currency' do
          it "returns amount multiplied by 'converted to' currency's rate" do
            expect(converted_money.amount).to eq(money.amount * money_config.rates[converted_money.currency])
          end
        end

        context 'when current currency differs from base conversion currency' do
          let(:money) { described_class.new(55.50, 'USD') }

          context 'when converted to base conversion currency' do
            it "returns amount devided by current currency's rate" do
              expect(money.convert_to(BASE_CURRENCY).amount).to eq(money.amount / money_config.rates[converted_money.currency])
            end
          end

          context 'when converted not to base conversion currency' do
            it "returns amount devided by current currency's rate and multiplied by 'converted to' currency's rate" do
              expect(money.convert_to('Bitcoin').amount).to eq(money.amount / money_config.rates[converted_money.currency] * money_config.rates['Bitcoin'])
            end
          end
        end
      end
    end

    let(:left_money) { described_class.new(1.5, 'EUR') }
    let(:right_money) { described_class.new(1, 'USD') }

    shared_examples_for 'currency-reducer method' do |method|
      it "result's currency equals to left money" do
        expect(left_money.send(method, right_money).currency).to eq('EUR')
      end
    end

    describe '#+' do
      it_behaves_like 'money-creator method', :+, 1
      it_behaves_like 'currency-reducer method', :+

      context 'when right money is a Money object' do
        it "converts right money's amount then sums up" do
          result = left_money + right_money
          expect(result.amount).to eq(left_money.amount + right_money.convert_to(left_money.currency).amount)
        end

        context 'when money are in the same currency' do
          let(:right_money) { described_class.new(1, 'EUR') }

          it 'returns a sum of two amounts' do
            result = left_money + right_money
            expect(result.amount).to eq(left_money.amount + right_money.amount)
          end
        end
      end

      context 'when right money is not a Money object' do
        it "converts addend to Float and sums up it with left money's amount" do
          result = left_money + 2
          expect(result.amount).to eq(left_money.amount + 2.to_f)
        end

        context 'when conversion failed' do
          it 'raises an error' do
            addend = [1]
            expect { left_money + addend }.to raise_error(TypeError, "Can't convert #{addend.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe '#-' do
      it_behaves_like 'money-creator method', :-, 1
      it_behaves_like 'currency-reducer method', :-

      context 'when right money is a Money object' do
        it "converts right money's amount then subtracts" do
          result = left_money - right_money
          expect(result.amount).to eq(left_money.amount - right_money.convert_to(left_money.currency).amount)
        end

        context 'when money are in the same currency' do
          let(:right_money) { described_class.new(1, 'EUR') }

          it 'returns subtraction of two amounts' do
            result = left_money - right_money
            expect(result.amount).to eq(left_money.amount - right_money.amount)
          end
        end
      end

      context 'when right money is not a Money object' do
        it "converts subtrahend to Float and subtracts it from left money's amount" do
          result = left_money - 2
          expect(result.amount).to eq(left_money.amount - 2.to_f)
        end

        context 'when conversion failed' do
          it 'raises an error' do
            subtrahend = [1]
            expect { left_money - subtrahend }.to raise_error(TypeError, "Can't convert #{subtrahend.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe '#/' do
      it_behaves_like 'money-creator method', :/, 1
      it_behaves_like 'currency-reducer method', :/

      context 'when right money is a Money object' do
        it "converts right money's amount then divide" do
          result = left_money / right_money
          expect(result.amount).to eq(left_money.amount / right_money.convert_to(left_money.currency).amount)
        end

        context 'when money are in the same currency' do
          let(:right_money) { described_class.new(0.5, 'EUR') }

          it 'returns division of two amounts' do
            result = left_money / right_money
            expect(result.amount).to eq(left_money.amount / right_money.amount)
          end
        end
      end

      context 'when right money is not a Money object' do
        it "converts divider to Float and divides left money's amount" do
          result = left_money / 2
          expect(result.amount).to eq(left_money.amount / 2.to_f)
        end

        context 'when conversion failed' do
          it 'raises an error' do
            divider = [1]
            expect { left_money / divider }.to raise_error(TypeError, "Can't convert #{divider.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe '#*' do
      it_behaves_like 'money-creator method', :*, 1
      it_behaves_like 'currency-reducer method', :*

      context 'when right money is a Money object' do
        it "converts right money's amount then divide" do
          result = left_money * right_money
          expect(result.amount).to eq(left_money.amount * right_money.convert_to(left_money.currency).amount)
        end

        context 'when money are in the same currency' do

          let(:right_money) { described_class.new(0.5, 'EUR') }

          it 'returns multiplication of two amounts' do
            result = left_money * right_money
            expect(result.amount).to eq(left_money.amount * right_money.amount)
          end
        end
      end

      context 'when right money is not a Money object' do
        it "converts multiplier to Float and multiplies left money's amount" do
          result = left_money * 2
          expect(result.amount).to eq(left_money.amount * 2.to_f)
        end

        context 'when conversion failed' do
          it 'raises an error' do
            multiplier = [1]
            expect { left_money * multiplier }.to raise_error(TypeError, "Can't convert #{multiplier.class.name} to Float. Please, provide either CurrencyConverter::Money or Float-convertible object.")
          end
        end
      end
    end

    describe '#==' do
      it 'returns false if compared object is not Money' do
        expect(left_money == (left_money + 1)).to be_falsey
      end

      it 'compares amounts with precision = 2' do
        left_money = described_class.new(0.1251, 'USD')
        right_money = described_class.new(0.1259, 'USD')
        expect(left_money == right_money).to be_truthy
      end

      context 'when compared money is in the same currency' do
        it 'compares amounts without conversion' do
          right_money = described_class.new(left_money.amount, left_money.currency)
          expect(left_money == right_money).to be_truthy
        end
      end

      context 'when compared money is in another currency' do
        it 'compares amounts after conversion' do
          right_money = left_money.convert_to('USD')
          expect(left_money == right_money).to be_truthy
        end
      end
    end

    describe '#<' do
      it 'raises an error if compared object is not Money' do
        expect { left_money < 0.5 }.to raise_error(ArgumentError, "comparison of #{left_money.class.name} with 0.5 failed")
      end

      context 'when compared money is in the same currency' do
        it 'compares amounts without conversion' do
          right_money = described_class.new(left_money.amount + 10, left_money.currency)
          expect(left_money < right_money).to be_truthy
        end
      end

      context 'when compared money is in another currency' do
        it 'compares amounts after conversion' do
          right_money = described_class.new(left_money.amount, 'Bitcoin')
          expect(left_money < right_money).to be_truthy
        end
      end
    end

    describe '#>' do
      it 'raises an error if compared object is not Money' do
        expect { left_money > 0.5 }.to raise_error(ArgumentError, "comparison of #{left_money.class.name} with 0.5 failed")
      end

      context 'when compared money is in the same currency' do
        it 'compares amounts without conversion' do
          right_money = described_class.new(left_money.amount - 1, left_money.currency)
          expect(left_money > right_money).to be_truthy
        end
      end

      context 'when compared money is in another currency' do
        it 'compares amounts after conversion' do
          right_money = described_class.new(left_money.amount, 'USD')
          expect(left_money > right_money).to be_truthy
        end
      end
    end
  end
end
