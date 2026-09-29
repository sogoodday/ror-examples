module Intercom
  class TrackEmailOpenedWorker < AsyncRunner
    unique!

    def run
      base_date = 1.day.ago
      IntercomService.client.contacts.search(
        :query => {
          :field    => 'last_email_opened_at',
          :operator => '>',
          :value    => 1.day.ago(base_date).beginning_of_day.to_i
        }
      ).to_a.each do |intercom_user|
        id = intercom_user.external_id.split('-').last
        user = User.find_by(id: id)
        next unless user

        # Let's do not create duplicates even if user read more than 1 email per day
        next if user.events
                    .where(key: Event::INTERCOM_EMAIL_OPENED_KEY)
                    .where("params-> 'email_opened_at' = ?", base_date.to_date).any?

        user.events.create(
          :key    => Event::INTERCOM_EMAIL_OPENED_KEY,
          :params => { email_opened_at: intercom_user.last_email_opened_at.to_date }
        )
      end
    end
  end
end
