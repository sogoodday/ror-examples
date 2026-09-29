module Holding
  class Bond < Holding
    include Holding::WithUnits
    include Holding::HasProxy

    validates :name, presence: true
    default_liquidity :medium
    allocation default: { asset_class: :bonds_general }

    DEFAULT_PAR_VALUE_MULTIPLIER = 100

    track_change_by do |params|
      total_units   = params.fetch(:units)
      price         = params.fetch(:price)
      date          = params.fetch(:date)
      units_change  = total_units - units_on(date)
      price_change  = price - latest_transaction.price
      kind          = if compare(units_change, 0).greater?
                        :investment
                      elsif compare(units_change, 0).less?
                        :redemption
                      elsif compare(price_change, 0).different?
                        :value_update
                      end
      units = if kind == :value_update
                total_units
              else
                units_change.abs
              end
      if kind
        {
          :units  => units,
          :price  => price,
          :kind   => kind,
          :date   => date,
          :change => nil
        }
      end
    end

    track_close_by do
      {
        :units => 0,
        :price => latest_transaction&.price || 0
      }
    end

    def security_based?
      true
    end

    def current_units
      latest_transaction&.total_units || 0
    end

    def create_initial_transaction!(units, price, opts = {})
      super(units * price / par_value_multiplier, { units: units, price: price }.merge(opts))
    end
  end
end
