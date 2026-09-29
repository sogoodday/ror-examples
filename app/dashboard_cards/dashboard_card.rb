class DashboardCard
  include Canopy::Configurable

  using Canopy::Refinements::StructObj

  config :perform, as: :block

  attr_reader :user, :period, :cards, :feature_set

  def initialize(user, period_end = Time.zone.now, cards = [], feature_set: nil)
    @user        = user
    @period      = Cashflow::Period.new(period_end)
    @cards       = cards
    @feature_set = feature_set || user&.feature_set || UserFeatureSet.null
  end

  def perform!
    struct(perform)
  end
end
