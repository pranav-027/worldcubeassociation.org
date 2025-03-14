# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V0::UserRolesController do
  describe 'GET #list' do
    let!(:user_senior_delegate_role) { FactoryBot.create(:senior_delegate_role) }
    let!(:user_whose_delegate_status_changes) { FactoryBot.create(:junior_delegate_role, group_id: user_senior_delegate_role.group_id).user }
    let!(:delegate) { FactoryBot.create :delegate_role, group_id: user_senior_delegate_role.group_id }
    let!(:person) { FactoryBot.create :person, dob: '1990-01-02' }
    let!(:user_who_claims_wca_id) do
      FactoryBot.create(
        :user,
        unconfirmed_wca_id: person.wca_id,
        delegate_id_to_handle_wca_id_claim: user_whose_delegate_status_changes.id,
        claiming_wca_id: true,
        dob_verification: "1990-01-2",
      )
    end
    let!(:banned_competitor) { FactoryBot.create(:banned_competitor_role) }

    context 'when user is logged in as senior delegate' do
      before do
        allow(controller).to receive(:current_user) { user_senior_delegate_role.user }
      end

      it 'fetches list of roles of a user' do
        get :index, params: { userId: user_whose_delegate_status_changes.id }

        expect(response.body).to eq(user_whose_delegate_status_changes.active_roles.to_json)
      end

      it 'does not fetches list of banned competitos' do
        get :index, params: { groupType: UserGroup.group_types[:banned_competitors] }

        expect(response.body).to eq([banned_competitor].to_json)
      end
    end

    context 'when user is logged in as a normal user' do
      sign_in { FactoryBot.create(:user) }

      it 'fetches list of roles of a user' do
        get :index, params: { userId: user_whose_delegate_status_changes.id }

        expect(response.body).to eq(user_whose_delegate_status_changes.active_roles.to_json)
      end

      it 'fetches list of banned competitos' do
        get :index, params: { groupType: UserGroup.group_types[:banned_competitors] }

        expect(response.body).to eq([].to_json)
      end

      it 'fetches list of roles of a region' do
        group = user_senior_delegate_role.group
        group_roles = group.roles

        get :index, params: { groupId: group.id }

        expect(response.body).to eq(group_roles.to_json)
      end
    end

    context 'when user is logged in as an admin' do
      sign_in { FactoryBot.create(:wst_admin_role).user }

      it 'does return banned_competitors if isGroupHidden is true' do
        get :index, params: { userId: banned_competitor.user.id, isGroupHidden: true }

        expect(response.body).to eq([banned_competitor].to_json)
      end

      it 'does not return banned_competitors if isGroupHidden is false' do
        get :index, params: { userId: banned_competitor.user.id, isGroupHidden: false }

        expect(response.body).to eq([].to_json)
      end
    end
  end

  describe 'GET #show' do
    let!(:delegate_role) { FactoryBot.create(:delegate_role) }
    let!(:probation_role) { FactoryBot.create(:probation_role) }

    context 'when delegate role is requested' do
      it 'returns the role' do
        get :show, params: { id: delegate_role.id }
        expect(response.body).to eq(delegate_role.to_json)
      end
    end

    context 'when probation role is requested' do
      it 'returns unauthorized error' do
        get :show, params: { id: probation_role.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST #create' do
    let!(:user_to_be_banned_with_past_comps) { FactoryBot.create(:user, :with_past_competitions) }
    let!(:user_to_be_banned_with_future_comps) { FactoryBot.create(:user, :with_future_competitions) }
    let!(:user_to_be_banned_with_deleted_registration_in_future_comps) { FactoryBot.create(:user, :with_deleted_registration_in_future_comps) }

    context 'when signed in as a WIC Leader' do
      sign_in { FactoryBot.create(:user, :wic_leader) }

      it 'can ban a user if the user does not have any upcoming competitions' do
        post :create, params: {
          userId: user_to_be_banned_with_past_comps.id,
          groupType: UserGroup.group_types[:banned_competitors],
        }
        expect(response).to be_successful
      end

      it 'can ban a user if the user have any upcoming competitions' do
        post :create, params: {
          userId: user_to_be_banned_with_future_comps.id,
          groupType: UserGroup.group_types[:banned_competitors],
        }
        expect(response).to be_successful
      end

      it "can ban a user if the user's upcoming competitions are after end date" do
        post :create, params: {
          userId: user_to_be_banned_with_future_comps.id,
          groupType: UserGroup.group_types[:banned_competitors],
          endDate: user_to_be_banned_with_future_comps.competitions_registered_for.not_over.merge(Registration.not_cancelled).first.end_date - 1,
        }
        expect(response).to be_successful
      end

      it 'can ban a user if the user have a deleted registration in an upcoming competitions' do
        post :create, params: {
          userId: user_to_be_banned_with_deleted_registration_in_future_comps.id,
          groupType: UserGroup.group_types[:banned_competitors],
        }
        expect(response).to be_successful
      end

      it 'can add a member to WIC' do
        user = FactoryBot.create(:user)

        expect(user.wic_team?).to be false
        post :create, params: {
          userId: user.id,
          groupId: UserGroup.teams_committees_group_wic.id,
          status: RolesMetadataTeamsCommittees.statuses[:member],
        }
        expect(response).to be_successful
        expect(user.reload.wic_team?).to be true
      end

      it 'can remove a member from WIC' do
        wic_role = FactoryBot.create(:wic_member_role, :active)

        expect(wic_role.user.wic_team?).to be true
        post :destroy, params: {
          id: wic_role.id,
        }
        expect(response).to be_successful
        expect(wic_role.user.reload.wic_team?).to be false
      end
    end

    context 'when signed in as a Senior Delegate' do
      sign_in { FactoryBot.create(:senior_delegate_role).user }

      it 'can create a new trainee delegate' do
        user_to_be_made_delegate = FactoryBot.create(:user)
        senior_delegate_role = FactoryBot.create(:senior_delegate_role)

        post :create, params: {
          userId: user_to_be_made_delegate.id,
          groupId: senior_delegate_role.group_id,
          status: RolesMetadataDelegateRegions.statuses[:trainee_delegate],
          location: 'USA',
        }

        expect(user_to_be_made_delegate.any_kind_of_delegate?).to be true
      end
    end

    context 'when signed in as a Board member' do
      sign_in { FactoryBot.create(:user, :board_member) }

      it "creating a new role for leader ends old delegate's role" do
        current_leader = FactoryBot.create(:wrt_leader_role)
        new_leader = FactoryBot.create(:user)

        post :create, params: {
          userId: new_leader.id,
          groupId: current_leader.group_id,
          status: RolesMetadataTeamsCommittees.statuses[:leader],
        }

        expect(current_leader.user.active_roles.count).to eq(0)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when signed in as a Senior Delegate' do
      sign_in { FactoryBot.create(:senior_delegate_role).user }

      it 'can end role of a junior delegate' do
        junior_delegate_role = FactoryBot.create(:junior_delegate_role)
        person = FactoryBot.create(:person)
        FactoryBot.create(:user, claiming_wca_id: true, dob_verification: person.dob, unconfirmed_wca_id: person.wca_id, delegate_id_to_handle_wca_id_claim: junior_delegate_role.user_id)

        delete :destroy, params: {
          id: junior_delegate_role.id,
        }

        expect(response).to be_successful
        expect(junior_delegate_role.user.any_kind_of_delegate?).to be false
      end
    end
  end
end
