class BenefitFocusFileProcessor
  class << self
    def process(filedata, filename)
      partner = Partner.find_by_key('benefit_focus')
      filedata.locate('iMax/Sender/Sponsors/Sponsor').each do |sponsor|
        employer = sponsor.locate('Name').first.text
        sponsor.locate('Contracts/Contract').each do |contract|
          subscriber_id = contract.locate('SubscriberID').first.text
          contract.locate('Member').each do |member|
            member_tt  = member.locate('Metadata/TransactionType').first.text
            benefit_tt = find_benefit(member).locate('TransactionType').first.text
            case [member_tt, benefit_tt]
            when %w[ADD AD], %w[REHIRE_REINSTATE RR], %w[CHANGE AD]
              BenefitFocus::CreateOrActivateUserWorker.run!(Ox.dump(member), filename, employer, subscriber_id)
            when %w[CHANGE AU]
              BenefitFocus::UpdateUserWorker.run!(Ox.dump(member), filename, subscriber_id)
            when %w[CHANGE CH]
              BenefitFocus::UpdateUserBenefitWorker.run!(Ox.dump(member), filename, subscriber_id)
            when %w[TERM CA]
              BenefitFocus::MarkUserAsCancelledWorker.run!(Ox.dump(member), filename, subscriber_id)
            when %w[TERM XX]
              BenefitFocus::MarkUserAsTerminatedWorker.run!(Ox.dump(member), filename, subscriber_id)
            else
              email, first_name, last_name = BenefitFocus::Errors.extract_user_data(member)
              e = BenefitFocus::Errors::BadTransactionTypeError.new(email, filename, first_name,
                                                                    last_name, [member_tt, benefit_tt])
              incident = partner.track_incident!(user: nil, data: e.to_hash, node: Ox.dump(filedata))
              Rollbar.error(e, incident_id: incident.id)
            end
          end
        end
      end
      partner.partner_events.create(key: 'file_processed', params: { filename: filename })
    end

    def find_benefit(benefits)
      benefits.locate('Benefits/Benefit').find do |benefit|
        benefit.locate('ProductID').first.text == 'fake-product-id'
      end
    end
  end
end
