class GoalDecorator < Draper::Decorator
  using Canopy::Refinements::StructObj
  include Canopy::Formatters

  decorates :goal
  delegate  :id, :key, :header, :description, :tips, :progress, :intervals, :achieved

  Chart = Struct.new(:data, :options, :type)

  def assets
    object.assets.sort_by(&:value).reverse.map do |asset|
      "#{Canopy::Formatters.dollars(asset.value)} in #{asset.name}"
    end
  end

  def started
    I18n.l(object.created_at.to_date, format: :month_year)
  end

  def estimated_end
    I18n.l(object.estimated_end.to_date, format: :month_year) if object.estimated_end
  end

  def value
    object.intervals.sum(&:value)
  end

  def progress_chart
    data = [%w[Month Missed Achieved]]
    intervals.each do |interval|
      data << [interval.label,
               interval.succeeded ? 0 : interval.value.round,
               interval.succeeded ? interval.value.round : 0]
    end

    options = {
      :width     => '100%',
      :height    => 150,
      :isStacked => true,
      :legend    => { position: 'none' },
      :bars      => 'vertical',
      :axes      => {
        :y => {
          0 => { side: 'right' },
          1 => { side: 'left' }
        }
      },
      :vAxis     => {
        :gridlines => { count: 1 },
        :format    => '$#,###'
      },
      :hAxis     => { title: '' },
      :series    => {
        0 => { color: 'red' },
        1 => { color: 'green' }
      },
      :animation => {
        :startup  => true,
        :duration => 1000
      }
    }

    Chart.new(data, options, 'columns')
  end

  def chart
    chart = progress_chart
    Chart.new(chart.data, chart.options.merge(width: '100%', height: 300), chart.type)
  end

  def subheading; end
end
