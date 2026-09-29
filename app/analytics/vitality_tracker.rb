class VitalityTracker < BaseTracker
  def track(user, event, async: true)
    return if skip_tracking?(user)

    block = lambda {
      data = {
        :memberId  => user.partner_guid,
        :eventId   => SecureRandom.random_number.to_s.tr('.', '').to_i,
        :eventCode => event,
        :eventDate => Time.now.strftime('%FT%T%z')
      }
      tracker.post_event(data, user)
    }
    if async
      safe_async { block.call }
    else
      block.call
    end
  end

  private

  def skip_tracking?(user)
    Rails.env.development? || Rails.env.test? || user.admin? || user.operator?
  end

  def tracker
    VitalityService
  end
end
