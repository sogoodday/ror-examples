module Admin
  class OrganizationsController < BaseController
    include TemplateRenderer

    before_action :require_admin
    before_action :find_organization, except: %i[index create check_job_status]
    layout :set_layout

    def index
      @organizations = Admin::OrganizationDecorator.decorate_collection(Organization.all.includes(:managers, :users))
      @statistics    = OrganizationsStatistics.prepare
    end

    def create
      @organization = Organization.new(organization_params)
      if @organization.save
        @organization.managers.each do |manager|
          @mixpanel_tracker.create_profile(manager, request.remote_ip)
          @intercom_tracker.create_user(manager)
          manager.invite!
          @event_tracker.track(manager, :invited)
          UserMailer.welcome_manager(manager.id).deliver_later
        end
        redirect_to admin_organizations_path, notice: 'New organization successfully created'
      else
        @organization.managers << @organization.managers.new if @organization.managers.empty?
        render 'new', notice: 'Error while creating organization'
      end
    end

    def specific_content
      @template = Slim::Template.new('fake-local-path').render(extend(ApplicationHelper))
    end

    def check_job_status
      job_id = params[:job_id]
      job_status = Sidekiq::Status.status(job_id)
      csv_result = Sidekiq::Status.get(job_id, :result)
      render json: { status: job_status, result: csv_result }
    end

    private

    def organization_params
      attrs = params.require(:organization)
                    .permit(:name, :domain, :partner_id, :tier_id, managers_attributes: [:email])
      attrs[:managers_attributes]['0'].merge!(password: PasswordFactory.create_password, role: :manager)
      attrs
    end

    def find_organization
      @organization = Organization.find(params[:id])
    end

    def set_layout
      pjax? ? false : 'admin/organizations'
    end
  end
end
