require 'rails_helper'

RSpec.describe UserRole, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:role) { create(:role, name: Role::ADMIN) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to belong_to(:role) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:organization_id) }
    it { is_expected.to validate_presence_of(:role_id) }

    describe 'uniqueness' do
      let!(:existing_user_role) do
        create(:user_role, user: user, organization: organization, role: role)
      end

      it 'prevents duplicate user-organization-role combinations' do
        new_user_role = build(:user_role, user: user, organization: organization, role: role)
        expect(new_user_role).not_to be_valid
        expect(new_user_role.errors[:user_id]).to be_present
      end

      it 'allows same user with different organizations' do
        other_org = create(:organization)
        new_user_role = build(:user_role, user: user, organization: other_org, role: role)
        expect(new_user_role).to be_valid
      end

      it 'does not allow same user with different roles in same organization' do
        other_role = create(:role, name: Role::USER)
        new_user_role = build(:user_role, user: user, organization: organization, role: other_role)
        expect(new_user_role).not_to be_valid
      end
    end
  end

  describe '#role_name' do
    let(:user_role) { create(:user_role, role: role) }

    it 'returns the role name' do
      expect(user_role.role_name).to eq(Role::ADMIN)
    end
  end

  describe '#user_name' do
    let(:user_role) { create(:user_role, user: user) }

    it 'returns the user name' do
      expect(user_role.user_name).to eq(user.name)
    end
  end

  describe '#organization_name' do
    let(:user_role) { create(:user_role, organization: organization) }

    it 'returns the organization name' do
      expect(user_role.organization_name).to eq(organization.name)
    end
  end
end
