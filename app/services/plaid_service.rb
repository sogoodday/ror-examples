class PlaidService
  TRANSACTION_OFFSET_LENGTH = 500
  class << self
    def get_accounts(item, account_ids = [])
      account_ids = Array.wrap(account_ids)
      request = if account_ids.any?
                  -> { client.accounts.get(item.access_token, account_ids: account_ids) }
                else
                  -> { client.accounts.get(item.access_token) }
                end

      request.call.tap do |response|
        log!(
          :user_id      => item.user_id,
          :event_name   => 'ACCOUNTS.GET',
          :item_id      => item.item_id,
          :request_id   => response.request_id,
          :access_token => item.access_token,
          :metadata     => response
        )
      end
    end

    def transactions_for(asset, start_date:, end_date:, offset: 0, count: TRANSACTION_OFFSET_LENGTH)
      request = lambda { |asset, start_date, end_date, offset, count|
        params = [asset.plaid_item.access_token,
                  start_date.to_date.to_s,
                  end_date.to_date.to_s,
                  { offset: offset, count: count }]

        transactions = lambda do |params|
          response = client.transactions.get(*params)
          [response.transactions, [], response.total_transactions]
        rescue Plaid::InvalidInputError => e
          raise if e.error_code == 'INVALID_ACCOUNT_ID'

          [[], [], 0]
        rescue Plaid::PlaidAPIError => e
          raise unless e.error_code == 'PRODUCT_NOT_READY'

          asset.sync_updates_status!(positions: e.error_code, transactions_status: e.error_code)
          [[], [], 0]
        end

        investments = lambda do |params|
          response = client.investments.transactions.get(*params)
          [response.investment_transactions, response.securities, response.total_investment_transactions]
        rescue Plaid::InvalidInputError => e
          raise if e.error_code == 'INVALID_ACCOUNT_ID'

          [[], [], 0]
        rescue Plaid::PlaidAPIError => e
          raise unless e.error_code == 'PRODUCTS_NOT_SUPPORTED'

          asset.sync_updates_status!(positions: e.error_code, transactions_status: e.error_code)
          [[], [], 0]
        end

        if asset.respond_to?(:online_investment?)
          params.last[:account_ids] = [asset.plaid_id]
          asset.online_investment? ? investments.call(params) : transactions.call(params)
        else
          for_cash, _, cash_total = transactions.call(params)
          for_investments, securities, investments_total = investments.call(params)
          [for_cash + for_investments, securities, cash_total + investments_total]
        end
      }

      result = [[], [], 0]

      loop do
        response = request.call(asset, start_date, end_date, offset, count)
        result[0] << response[0]
        result[1] << response[1]
        result[2]  = response[2]
        offset += response[0].length
        break unless response[0].length.positive? && offset < count
      end

      log!(
        :user_id      => asset.user_id,
        :event_name   => 'TRANSACTIONS.GET',
        :item_id      => asset.plaid_item.item_id,
        :request_id   => nil,
        :access_token => asset.plaid_item.access_token,
        :metadata     => { count: result.flatten.count }
      )
      [result[0].flatten, result[1].flatten, result[2]]
    end

    def log!(attrs)
      PlaidLog.create(attrs.merge(source: 'api'))
    end
  end
end
