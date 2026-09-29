class NetWorthCard < DashboardCard
  include Canopy::Formatters

  CATEGORY_MAPPINGS = {
    :assets      => {
      :checking    => 'Savings',
      :investment  => 'Investments',
      :private     => 'Investments',
      :real_estate => 'Other',
      :alternative => 'Investments',
      :other       => 'Other',
      nil          => 'Other'
    },
    :liabilities => {
      :credit          => 'Credit Cards',
      :mortgage        => 'Mortgage',
      :loan            => 'Loans',
      :negative_assets => 'Loans',
      nil              => 'Loans'
    }
  }.freeze

  perform do
    if user.has_no_assets?
      {
        :chart => nil
      }
    else
      options = {
        :legend    => { position: 'none' },
        :fontSize  => 14,
        :fontName  => 'Lato',
        :height    => 340,
        :bar       => { groupWidth: '80%' },
        :hAxis     => {
          :gridlines      => { count: 0 },
          :viewWindowMode => 'maximized',
          :ticks          => []
        },
        :vAxis     => {
          :gridlines => { count: 0 },
          :textStyle => { bold: true }
        },
        :chartArea => {
          :height => 270,
          :top    => -40,
          :left   => 130
        }
      }

      collect_values = lambda do |balance, kind, color, date|
        balance.send(kind).map do |group|
          [
            group.category.key,
            group.total,
            group.items.sum { |item| item.object.value_on(date) }
          ]
        end.group_by do |row|
          CATEGORY_MAPPINGS[kind].fetch(row[0])
        end.map do |name, groups|
          [name, groups.sum { |row| row[1] }, groups.sum { |row| row[2] * (kind == :assets ? 1 : -1) }]
        end.map.with_index do |row, index|
          lighten_color = Sass::Script::Parser.parse("lighten(#{color}, #{index * 10})", 0, 0).perform(Sass::Environment.new)
          [row[0], row[1], row[2], lighten_color.to_s]
        end
      end

      add_placeholders = lambda do |data, categories|
        categories.each { |category| data.push([category, 0, 0, '']) unless data.any? { |row| row.first == category } }
        data
      end

      balance = BalanceSheet.build_for_user!(user, full_load: false)
      date = 1.month.ago
      rows = []
      rows.push(*collect_values.call(balance, :assets, '#5fbfa2', date))
      add_placeholders.call(rows, %w[Banking Investments])
      rows.push(*collect_values.call(balance, :liabilities, '#e27d6f', date))
      add_placeholders.call(rows, ['Credit Cards', 'Loans'])

      data = [['Category', 'Value', { role: 'style' }, { role: 'tooltip' }]]
      rows.each do |row|
        data << [row[0], row[1], row[3], "#{row[0]}: #{dollars(row[1])}"]
      end

      previous = rows.sum { |row| row[2] }

      {
        :chart => {
          :data    => data,
          :options => options
        },
        :total => dollars(balance.total),
        :icon  => balance.total > previous ? 'up' : 'down'
      }
    end
  end
end
