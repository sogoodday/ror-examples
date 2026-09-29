class Goal < ActiveRecord::Base
  include Canopy::Configurable
  include Canopy::Formatters

  belongs_to :user
  belongs_to :asset, polymorphic: true
  has_many :contributions, dependent: :destroy

  TimeSlot = Struct.new(:start, :end, :initial) do
    def label
      start.strftime('%B')
    end
  end
  Interval = Struct.new(:time_slot, :label, :value, :succeeded)
  Progress = Struct.new(:time_slot, :target, :fact, :succeeded)

  config :header,         as: :block
  config :description,    as: :block, default: -> { @description }
  config :assets,         as: :block
  config :progress,       as: :block
  config :intervals,      as: :block, default: nil
  config :succeeded,      as: :block
  config :estimated_end,  as: :block, default: -> {}
  config :tips,           as: :block

  config :contribute!,    as: :block, default: ->(_, amount, _) { amount }

  config :period,         as: :block, default: lambda {
    today = Time.zone.today.to_time
    start = [created_at, 6.months.ago(today).beginning_of_month].max
    start..today.end_of_day
  }

  def key
    self.class.to_s.demodulize.underscore
  end

  private

  def time_slots
    slots = []
    period_start = period.begin
    period_end   = period.end
    while period_start < period_end
      end_at = [period_start.end_of_month, period_end].min
      slots << TimeSlot.new(period_start.beginning_of_day, end_at.end_of_day, period_start == created_at)
      period_start = period_start.next_month.beginning_of_month
    end
    slots
  end

  def current_value
    contributions.sum(:amount)
  end

  def left_to_save
    amount - current_value
  end
end
