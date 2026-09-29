module SummaryBlockHelper
  def summary_profit(value)
    profit(value, precision: 0)
  end

  def summary_block(title, value = 0, value_class = '', extra = nil)
    content_tag(:div, class: 'grid-column') do
      header  = content_tag(:div, title, class: 'summary-block_name')
      content = content_tag(:div, class: 'summary-block_value') do
        if block_given?
          yield
        else
          span  = content_tag(:span, value, class: value_class)
          small = content_tag(:small, " / #{extra}") if extra
          span + small.to_s
        end
      end
      header + content
    end
  end
end
