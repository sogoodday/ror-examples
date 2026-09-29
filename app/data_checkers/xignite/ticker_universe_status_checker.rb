# Reason: Reason why this checker was added
# Fix: What to do to fix an issue
# Tags: quotes, xignite
module Checkers
  module Xignite
    class TickerUniverseStatusChecker < BaseChecker
      include ActionView::Helpers::DateHelper

      title 'Stale Tickers'
      description 'List of tickers without recent quotes'
      columns 'Ticker', 'Holdings', 'Last Quote At'

      rows do
        Holidays.between(2.weeks.ago, Time.zone.today, :us).each do |holiday|
          BusinessTime::Config.holidays << holiday[:date]
        end

        yesterday = 1.business_day.ago.to_date
        day_before_yesterday = 2.business_day.ago.to_date
        tickers = []
        [
          [:equity, yesterday],
          [:etf_fund, yesterday],
          [:mutual_fund, day_before_yesterday]
        ].each do |type, date|
          Ticker
            .listed
            .send(type)
            .where('last_updated_quote_at < ?', date)
            .pluck(:id, :code, :last_updated_quote_at)
            .each do |id, code, time|
              holdings = Holding.opened.by_ticker(id).pluck(:id)
              tickers << [code, holdings, time_ago_in_words(time)] if holdings.any?
            end
        end
        tickers
      end
    end
  end
end
