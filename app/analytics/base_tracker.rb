class BaseTracker
  def initialize(controller)
    @controller = controller
  end

  private

  def safe_async
    Thread.new do
      yield
    rescue StandardError => e
      Rollbar.error(e)
      Rails.logger.error("Failed tracking: #{e.inspect}")
    end
  end

  def skip_tracking?(user)
    Rails.env.development? || Rails.env.test? || user.admin? || user.operator?
  end
end
