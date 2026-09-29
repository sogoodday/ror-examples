module BalanceSheet
  module Builder
    def self.build(user, full_load: true)
      assets = BalanceSheet::Storage.new(user, full_load: full_load).fetch_assets!
      groups = BalanceSheet::Aggregator.new(*assets).aggregate!
      BalanceSheet::Page.new(*groups)
    end
  end
end
