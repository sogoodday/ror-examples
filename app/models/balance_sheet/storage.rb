module BalanceSheet
  class Storage
    UnknownAssetTypeError = Class.new(StandardError)
    attr_reader :user, :full_load

    def initialize(user, full_load: true)
      @user = user
      @full_load = full_load
    end

    def fetch_asset!(type, id)
      case type.new
      when ::Account
        fetch_accounts!(user.accounts.where(id: id))
      when ::Holding
        fetch_holdings!(user.holdings.where(id: id))
      when ::Liability
        fetch_liabilities!(user.liabilities.where(id: id))
      else
        raise UnknownAssetTypeError.new
      end.first
    end

    def fetch_assets!
      accounts    = fetch_accounts!
      holdings    = fetch_holdings!
      liabilities = fetch_liabilities!
      [accounts, holdings, liabilities]
    end

    private

    def fetch_holdings!(scope = user.holdings.opened)
      holdings = scope.with_total_units.includes(:parent_account, :plaid_item)
      stocks   = holdings.select(&:stock?)
      proxable = holdings.select(&:proxable?)

      if full_load
        Holding.preload_allocations_for(holdings)
        ActiveRecord::Associations::Preloader.new.preload(proxable, %i[proxy auto_proxy])
        Holding::Stock.preload_tickers(stocks)

        DefaultProxy.preload_cache!
      end

      holdings.map do |holding|
        BalanceSheet::Holding.new(
          :id          => holding.id,
          :parent_id   => holding.parent_account_id,
          :name        => full_load && holding.name,
          :category    => holding.category_object,
          :notes       => holding.notes,
          :value       => holding.value,
          :liquidity   => holding.liquidity,
          :ownership   => holding.ownership,
          :online      => full_load && holding.online?,
          :ticker      => full_load && holding.stock? ? holding.ticker : nil,
          :units       => holding.total_units,
          :proxy       => full_load && holding.benchmark,
          :residence   => holding.real_estate? ? holding.primary_residence : nil,
          :asset_class => full_load && HoldingAllocation.title_for(holding, :asset_class),
          :region      => full_load && HoldingAllocation.title_for(holding, :region),
          :sector      => full_load && HoldingAllocation.title_for(holding, :sector),
          :updated_at  => full_load && holding.updated_at
        )
      end
    end

    def fetch_accounts!(scope = user.accounts)
      accounts = scope.with_total_value.includes(:parent_account, :plaid_item)
      accounts.map do |account|
        BalanceSheet::Account.new(
          :id          => account.id,
          :parent_id   => account.parent_account_id,
          :name        => account.name,
          :category    => account.category_object,
          :notes       => account.notes,
          :value       => account.total_value,
          :liquidity   => account.liquidity,
          :ownership   => account.ownership,
          :online      => full_load && account.online?,
          :institution => account.bank_name,
          :updated_at  => full_load && account.last_good_synced_at
        )
      end
    end

    def fetch_liabilities!(scope = user.liabilities)
      liabilities = scope.includes(:plaid_item)
      liabilities.map do |liability|
        BalanceSheet::Liability.new(
          :id          => liability.id,
          :name        => liability.name,
          :category    => liability.category_object,
          :notes       => liability.notes,
          :value       => -liability.current_value,
          :online      => full_load && liability.online?,
          :institution => liability.bank_name,
          :updated_at  => full_load && liability.last_good_synced_at,
          :parent_id   => nil
        )
      end
    end
  end
end
