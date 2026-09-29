module BalanceSheet
  class Page
    include Canopy::Formatters
    extend Memoist

    attr_reader :assets, :liabilities, :assets_total, :liabilities_total, :total

    def initialize(assets, liabilities)
      @assets            = assets
      @liabilities       = liabilities
      @assets_total      = assets.sum(&:total)
      @liabilities_total = liabilities.sum(&:total)
      @total             = @assets_total + @liabilities_total
    end

    def assets_dollars
      dollars(@assets_total)
    end

    def liabilities_dollars
      dollars(@liabilities_total)
    end

    def total_dollars
      dollars(@total)
    end

    def expand!(keys)
      items_by_keys.each do |key, item|
        if keys.include?(key)
          item.expand!
        else
          item.collapse!
        end
      end
    end

    def select!(item)
      items_by_keys[item.key].select!
    end

    def as_pdf!
      @as_pdf = true
    end

    def pdf?
      !!@as_pdf
    end

    def html?
      !pdf?
    end

    private

    def items_by_keys
      items = {}
      walk_on_group(assets, items)
      walk_on_group(liabilities, items)
      items
    end

    def walk_on_group(items, hash)
      items.each do |item|
        hash[item.key] = item
        walk_on_group(item.items, hash)
      end
    end

    memoize :items_by_keys
  end
end
