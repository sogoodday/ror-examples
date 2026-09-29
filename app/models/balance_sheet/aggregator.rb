module BalanceSheet
  class Aggregator
    def initialize(accounts, holdings, liabilities)
      @accounts    = accounts
      @holdings    = holdings
      @liabilities = liabilities
    end

    def aggregate!
      account_groups = accounts.group_by(&:parent_id)
      holding_groups = holdings.group_by(&:parent_id)

      negative_accounts, account_groups[nil] = extract_negative_assets(account_groups[nil])
      negative_holdings, holding_groups[nil] = extract_negative_assets(holding_groups[nil])
      negative_liabilities, positive_liabilities = extract_negative_assets(liabilities, true)

      root_accounts = roots(account_groups)
      root_holdings = roots(holding_groups)

      accounts.each do |account|
        account.items = assets_for(account.id, account_groups) + assets_for(account.id, holding_groups)
      end

      categories = (root_accounts.keys + root_holdings.keys).uniq.sort_by(&:position)
      category_other = BalanceSheet::Category.category_other
      (categories << category_other).uniq! if positive_liabilities.any?

      account_groups = categories.map do |category|
        liabilities = category == category_other ? positive_liabilities : []
        BalanceSheet::Group.new(:asset, category, assets_for(category, root_accounts),
                                assets_for(category, root_holdings), liabilities)
      end

      root_liabilities = negative_liabilities.group_by(&:category)

      categories = root_liabilities.keys.sort_by(&:position)
      category_negative_assets = BalanceSheet::Category.category_negative_assets
      (categories << category_negative_assets).uniq! if negative_accounts.any? || negative_holdings.any?

      liabilities_groups = categories.map do |category|
        accounts, holdings = category == category_negative_assets ? [negative_accounts, negative_holdings] : [[], []]
        BalanceSheet::Group.new(:liability, category, accounts, holdings, assets_for(category, root_liabilities))
      end

      [account_groups, liabilities_groups]
    end

    def assets_for(key, group)
      (group[key] || []).sort_by(&:name)
    end

    def roots(groups)
      (groups[nil] || []).group_by(&:category)
    end

    private

    attr_reader :accounts, :holdings, :liabilities

    def extract_negative_assets(array, allow_zero: false)
      comparer = allow_zero ? ->(a) { a <= 0 } : lambda(&:negative?)
      (array || []).partition { |item| comparer.call(item.value) }
    end
  end
end
