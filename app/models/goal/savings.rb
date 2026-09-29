module Goal
  class Savings < Goal
    header do
      "Save #{currency(amount, precision: 0)} for #{name}"
    end

    description do
      [
        'Setting goals for yourself is a big step in the right direction. ',
        "We'll track your progress and let you know when you've hit your savings goal, ",
        "so check back in here to see how you're doing."
      ].join
    end

    assets do
      user.accounts.online.where(category: 'checking').to_a
    end

    progress do
      Progress.new(intervals.last.time_slot, amount, current_value, achieved)
    end

    intervals do
      time_slots.map do |slot|
        value = contributions.where(date: slot.start..slot.end).sum(:amount)
        Interval.new(slot, slot.label, value, value >= monthly_payment)
      end
    end

    contribute! do |asset, contribution, date|
      checking = asset.in?(assets)
      rest_to_contribute = if achieved
                             contribution
                           elsif checking && contribution.positive?
                             value = [contribution, left_to_save].min
                             contributions.create(amount: value, date: date)
                             rest = contribution - value
                             rest.positive? ? rest : 0
                           elsif checking && contribution.negative?
                             value = [contribution, - current_value].max
                             rest  = contribution - value
                             contributions.create(amount: value, date: date)
                             rest.negative? ? rest : 0
                           else
                             contribution
                           end
      update(achieved: true) if current_value == amount
      rest_to_contribute
    end

    estimated_end do
      tomorrow = Time.zone.tomorrow
      saved    = current_value
      started  = created_at.to_date
      shift = if amount.zero?
                0.days
              elsif saved.zero?
                duration.months
              else
                ((amount - saved) * (tomorrow - started) / saved).to_i.days
              end
      tomorrow + shift
    end

    tips [
      "If you can cut back on other expenses you'll save more and reach your goal sooner."
    ]
  end
end
