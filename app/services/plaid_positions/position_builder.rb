module PlaidPositions
  class PositionBuilder
    CASH_POSITION_TICKER = 'CUR:USD'.freeze

    attr_reader :default_date, :initiator

    def initialize(default_date, initiator)
      @default_date = default_date
      @initiator = initiator
    end

    def build(raw_position, security)
      date           = default_date

      ticker_code    = security[:ticker_symbol] || security[:institution_security_id]
      ticker_name    = security.fetch(:name, nil)
      ticker         = TickerSearch.find_or_create_ticker(ticker_code)

      cusip          = security.fetch(:cusip, nil)
      name           = ticker_code.present? && ticker_code != CASH_POSITION_TICKER ? ticker_code : 'Cash'
      security_name  = [ticker_name, ticker_code || cusip].compact.join(' / ')
      security_type  = security_type(security.fetch(:type, nil))

      units          = decimal(raw_position.fetch(:quantity))
      price          = decimal(security[:close_price] || raw_position[:institution_price])
      raw_value      = decimal(raw_position.fetch(:institution_value))
      ticker_price   = historical_closing_price(ticker, date, raw_value, units, price)

      cls = case security_type
            when :cash
              :cash
            when :bond
              :bond
            when :stock
              if ticker.present?
                :stock
              elsif TickerSearch.when_issued?(ticker_code)
                :stock_wi
              else
                :unknown_stock
              end
            else
              if raw_value.zero?
                :bankrupt
              else
                :unknown_stock
              end
            end

      params = {
        :raw       => raw_position,
        :date      => date,
        :raw_value => raw_value,
        :initiator => initiator
      }

      extra = case cls
              when :stock
                { ticker: ticker, price: ticker_price, units: units }
              when :stock_wi
                { name: ticker_code, price: price, units: units }
              when :bond
                { name: security_name, price: price, units: units }
              when :cash
                { name: name }
              when :bankrupt
                { name: security_name }
              when :unknown_stock
                { name: security_name, units: units }
              else
                { name: name }
              end

      klass = "PlaidPositions::#{cls.to_s.classify}".constantize
      klass.new(params.merge(extra))
    end

    private

    def historical_closing_price(ticker, date, market_value, units, default_price)
      return nil unless ticker

      calculated_price = calculated_price(market_value, units, default_price)
      return calculated_price if ENV['NO_XIGNITE'] || !ticker.is_listed?

      Xignite::PricesService.historical_closing_price(ticker, date, default: calculated_price)
    rescue StandardError => e
      Rails.logger.warn("#{self.class} error. Error loading price data for #{ticker.code}. Exception info: #{e}")
      calculated_price
    end

    def calculated_price(market_value, units, default_price)
      return default_price if default_price

      market_value / units if market_value && units && units != 0
    end

    def security_type(value)
      case value
      when 'cash'
        :cash
      when 'derivative', 'equity', 'etf', 'mutual\ fund'
        :stock
      when 'fixed income'
        :bond
      else
        :unknown_stock
      end
    end

    def decimal(value)
      BigDecimal(value, 0).round(3) unless value.nil?
    end
  end
end
