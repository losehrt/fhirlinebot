require 'rails_helper'

RSpec.describe LineLoginOrganizationHandler do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  before { Role.default_roles }

  describe '.handle_organization_assignment' do
    context 'when organization has no users (first user)' do
      it 'assigns admin role to the user' do
        user_role = described_class.handle_organization_assignment(user, organization)

        expect(user_role).to be_persisted
        expect(user_role.role.name).to eq(Role::ADMIN)
        expect(user_role.user).to eq(user)
        expect(user_role.organization).to eq(organization)
      end

      it 'marks the user as organization member' do
        described_class.handle_organization_assignment(user, organization)

        expect(user.member_of_organization?(organization.id)).to be_truthy
      end

      it 'makes the user an admin of the organization' do
        described_class.handle_organization_assignment(user, organization)

        expect(user.admin_in_organization?(organization.id)).to be_truthy
      end
    end

    context 'when organization already has users' do
      let!(:admin_user) { create(:user, :with_line_account) }

      before do
        # Create admin user first
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(admin_user, admin_role)
      end

      it 'assigns user role to the new user' do
        user_role = described_class.handle_organization_assignment(user, organization)

        expect(user_role).to be_persisted
        expect(user_role.role.name).to eq(Role::USER)
      end

      it 'does not make the new user an admin' do
        described_class.handle_organization_assignment(user, organization)

        expect(user.admin_in_organization?(organization.id)).to be_falsy
      end

      it 'makes the new user a regular member' do
        described_class.handle_organization_assignment(user, organization)

        expect(user.member_of_organization?(organization.id)).to be_truthy
      end
    end
  end

  describe '.first_user?' do
    context 'when organization has no users' do
      it 'returns true' do
        expect(described_class.first_user?(organization)).to be_truthy
      end
    end

    context 'when organization has users' do
      before do
        role = Role.find_by_name(Role::USER)
        organization.assign_role(user, role)
      end

      it 'returns false' do
        expect(described_class.first_user?(organization)).to be_falsy
      end
    end
  end

  describe '.promote_to_admin' do
    before do
      user_role = Role.find_by_name(Role::USER)
      organization.assign_role(user, user_role)
    end

    it 'assigns admin role to the user' do
      result = described_class.promote_to_admin(user, organization)

      expect(result.role.name).to eq(Role::ADMIN)
    end

    it 'makes the user an admin of the organization' do
      described_class.promote_to_admin(user, organization)

      expect(user.reload.admin_in_organization?(organization.id)).to be_truthy
    end
  end

  describe '.demote_to_user' do
    before do
      admin_role = Role.find_by_name(Role::ADMIN)
      organization.assign_role(user, admin_role)
    end

    it 'assigns user role to the user' do
      result = described_class.demote_to_user(user, organization)

      expect(result.role.name).to eq(Role::USER)
    end

    it 'removes admin status from the user' do
      described_class.demote_to_user(user, organization)

      expect(user.reload.admin_in_organization?(organization.id)).to be_falsy
    end
  end
end
