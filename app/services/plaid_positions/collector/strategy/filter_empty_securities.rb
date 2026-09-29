module PlaidPositions
  module Collector
    module Strategy
      class FilterEmptySecurities < Base
        SECURITY_TYPES = [
          PlaidPositions::Stock,
          PlaidPositions::UnknownStock,
          PlaidPositions::Bond
        ].freeze

        def collect!(positions)
          positions.reject do |position|
            security?(position) && position.units.present? && compare(position.units, 0).equal?
          end
        end

        def security?(position)
          position.class.in?(SECURITY_TYPES)
        end
      end
    end
  end
end
