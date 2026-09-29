module Api
  module User
    class Destroy < Trailblazer::Operation
      include Api::JsonOperation
      include Policy::Guard

      policy do |current_user:, organization_id:, **|
        current_user.support? ||
          (current_user.manager? && current_user.organization_id == Integer(organization_id))
      end

      def model!(organization_id:, id:, **)
        ::User.find_by(organization_id: organization_id, id: id)
      end

      def process(**)
        model.terminate!
      end
    end
  end
end
