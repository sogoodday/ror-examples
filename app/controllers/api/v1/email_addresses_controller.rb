module Api
  module V1
    class EmailAddressesController < BaseController
      def validate
        process_operation(Api::EmailAddress::Validate, :email_address)
      end

      def validate_list
        process_operation(Api::EmailAddress::ValidateList, :email_addresses, data: params)
      end

      def validate_csv
        process_operation(Api::EmailAddress::ValidateCsv, :email_addresses, data: params)
      end
    end
  end
end
