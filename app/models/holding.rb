class Holding < ActiveRecord::Base
  include AccountConcern::AdditionalData
  include AccountConcern::Liquidity
  include AccountConcern::HasCategory
  include Asset::Transactions
  include AccountConcern::WithParentAccount
  include AccountConcern::InitializedStatus
  include AccountConcern::Closed
  include AccountConcern::Taxable
  include Asset::Removable
  include Asset::Plaid
  include WithActivity
  include UpdateUserTimestamps
  include Holding::WithAllocation

  belongs_to :user, inverse_of: :holdings
  belongs_to :ticker, inverse_of: :holdings

  scope :positive, -> { where('current_value > 0') }
  scope :ordered,  -> { order(:name) }
  scope :stock,    -> { where(type: Holding::Stock.to_s) }
  scope :cash,     -> { where(type: Holding::Cash.to_s) }
  # more scopes

  track_activity_if do
    parent_account.nil? || parent_account.created_at.to_date != created_at.to_date
  end

  def parent?
    false
  end

  def security_based?
    false
  end

  def cash?
    false
  end

  def benchmark
    if is_a?(Holding::HasProxy)
      effective_proxy
    else
      DefaultProxy.for(self)
    end
  end

  def stock?
    is_a?(Holding::Stock)
  end

  def proxable?
    is_a?(Holding::HasProxy)
  end
end
