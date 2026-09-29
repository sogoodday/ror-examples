module Calendly
  class WebhookController < ActionController::Base
    def handle
      WebhookLog.calendly.create!(data: params, sender: request.remote_ip)

      event   = params[:event]
      payload = params[:payload]
      process_data(event, payload)
      head :ok
    end

    private

    def process_data(event, payload)
      case event
      when 'invitee.canceled'
        rescheduled = payload['rescheduled']
        unless rescheduled
          if (appointment = CoachingAppointment.find_by(event_url: payload['event']))
            appointment.destroy!
          else
            Rollbar.warn('[Calendly Webhook] No event found', { url: payload['event'] })
          end
        end
      when 'invitee.created'
        rescheduled = payload['old_invitee'].present?
        if rescheduled
          if (appointment = CoachingAppointment.find_by(invitee_url: payload['old_invitee']))
            event_data   = CalendlyService.retrieve_resource(payload['event'])
            invitee_data = CalendlyService.retrieve_resource(payload['uri'])
            appointment.update!(
              :event_name       => event_data['name'],
              :event_url        => event_data['uri'],
              :invitee_url      => payload['uri'],
              :event_start_time => event_data['start_time'],
              :event_end_time   => event_data['end_time'],
              :invitee_timezone => invitee_data['timezone'],
              :cancel_url       => invitee_data['cancel_url'],
              :reschedule_url   => invitee_data['reschedule_url']
            )
          else
            Rollbar.warn('[Calendly Webhook] No event found', { url: payload['event'] })
          end
        else
          user = User.by_email(payload['email'])
          if user
            appointment  = user.coaching_appointments.find_or_initialize_by(event_url: payload['event'])
            event_data   = CalendlyService.retrieve_resource(payload['event'])
            invitee_data = CalendlyService.retrieve_resource(payload['uri'])
            appointment.update!(
              :event_name       => event_data['name'],
              :event_url        => event_data['uri'],
              :invitee_url      => payload['uri'],
              :event_start_time => event_data['start_time'],
              :event_end_time   => event_data['end_time'],
              :invitee_timezone => invitee_data['timezone'],
              :cancel_url       => invitee_data['cancel_url'],
              :reschedule_url   => invitee_data['reschedule_url']
            )
          else
            Rollbar.error('[Calendly Webhook] No user found', { email: payload['email'], url: payload['uri'] })
          end
        end
      end
    end
  end
end
