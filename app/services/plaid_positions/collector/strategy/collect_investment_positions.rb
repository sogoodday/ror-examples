module PlaidPositions
  module Collector
    module Strategy
      class CollectInvestmentPositions < Base
        def collect!(positions)
          if data.holdings
            builder = PlaidPositions::PositionBuilder.new(collector.date, initiator)
            plaid_positions = data.holdings.holdings.map do |position|
              builder.build(position, data.holdings.securities.find { |item| item.security_id == position.security_id })
            end
            positions.unshift(*plaid_positions)
          else
            positions
          end
        end
      end
    end
  end
end
