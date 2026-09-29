module PlaidPositions
  module Collector
    class Collector
      DEFAULT_STRATEGIES_SEQUENCE = %i[
        collect_investment_positions
        collect_plug

        collect_cash

        filter_empty_securities
        merge_duplicates

        check_invalid_positions
      ].freeze

      attr_reader :plaid_id, :date, :strategies

      def initialize(plaid_id, strategies: nil)
        @plaid_id       = plaid_id
        @date           = Time.zone.today
        @data_service   = DataSource.new(plaid_id)
        @strategies     = strategies || DEFAULT_STRATEGIES_SEQUENCE
      end

      def collect!
        strategies.map(&method(:strategy_class)).inject([]) do |positions, strategy|
          strategy.new(self, @data_service).collect!(positions)
        end
      end

      protected

      def strategy_class(name)
        "PlaidPositions::Collector::Strategy::#{name.to_s.camelcase}".constantize
      end
    end
  end
end
