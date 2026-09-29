module Api
  module User
    class Create < Trailblazer::Operation
      contract do
        property :email
        property :canonical_email
        property :password, validates: { presence: true }

        validates_uniqueness_of :email
        validates_uniqueness_of :canonical_email
      end

      def model!(organization_id:, partner_id:, **)
        ::Organization.find(organization_id).users.investor.new(partner_id: partner_id)
      end

      def process(params)
        validate(params, &:save)
      end
    end
  end
end
