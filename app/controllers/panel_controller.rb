# frozen_string_literal: true

class PanelController < ApplicationController
  include DocumentsHelper

  before_action :authenticate_user!
  before_action -> { redirect_to_root_unless_user(:has_permission?, 'can_access_panels', params[:panel_id].to_sym) }, only: [:index]
  before_action -> { redirect_to_root_unless_user(:has_permission?, 'can_access_panels', :staff) }, only: [:staff]
  before_action -> { redirect_to_root_unless_user(:has_permission?, 'can_access_panels', :admin) }, only: [:generate_db_token]
  before_action -> { redirect_to_root_unless_user(:can_access_senior_delegate_panel?) }, only: [:pending_claims_for_subordinate_delegates]

  def pending_claims_for_subordinate_delegates
    # Show pending claims for a given user, or the current user, if they can see them
    user_id = params[:user_id] || current_user.id
    @user = User.find(user_id)
    @subordinate_delegates = @user.subordinate_delegates.to_a.push(@user)
  end

  def index
    @panel_id = params.require(:panel_id)
    panel_details = User.panel_list[@panel_id.to_sym]
    @pages = panel_details[:pages]
    @title = panel_details[:name]
    # This awkward mapping is necessary because `panel_notifications` returns callables
    #   which compute the value _if needed_. The point is to reduce workload, not every time
    #   that `User.panel_notifications` is called should trigger an actual computation.
    @notifications = User.panel_notifications.slice(*@pages).transform_values(&:call)
  end

  def generate_db_token
    @db_endpoints = {
      main: EnvConfig.DATABASE_HOST,
      replica: EnvConfig.READ_REPLICA_HOST,
    }

    role_credentials = Aws::ECSCredentials.new
    token_generator = Aws::RDS::AuthTokenGenerator.new credentials: role_credentials

    @db_tokens = @db_endpoints.transform_values do |url|
      token_generator.auth_token({
                                   endpoint: "#{url}:3306",
                                   user_name: EnvConfig.DATABASE_WRT_USER,
                                   region: EnvConfig.AWS_REGION,
                                 })
    end

    @db_server_indices = {
      main: 1,
      replica: 2,
    }
  end

  def panel_page
    panel_page_id = params.require(:id)
    panel_with_panel_page = current_user.panels_with_access&.find { |panel| User.panel_list[panel][:pages].include?(panel_page_id) }

    return head :unauthorized if panel_with_panel_page.nil?

    query_params = request.query_parameters.except(:id)
    redirect_to panel_index_path(panel_id: panel_with_panel_page, anchor: panel_page_id, **query_params)
  end
end
