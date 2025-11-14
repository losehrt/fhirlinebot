require 'rails_helper'

RSpec.describe UserPolicy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:organization) { create(:organization) }

  before { Role.default_roles }

  describe '#show?' do
    context 'when user views their own profile' do
      it 'permits access' do
        expect(described_class.new(user, user)).to permit(:show)
      end
    end

    context 'when user is admin of organization where other user is member' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, admin_role)
        organization.assign_role(other_user, user_role)
      end

      it 'permits access' do
        expect(described_class.new(user, other_user)).to permit(:show)
      end
    end

    context 'when user views other user profile without permission' do
      it 'denies access' do
        expect(described_class.new(user, other_user)).not_to permit(:show)
      end
    end
  end

  describe '#update? and #edit?' do
    context 'when user updates their own profile' do
      it 'permits access' do
        policy = described_class.new(user, user)
        expect(policy).to permit(:update)
        expect(policy).to permit(:edit)
      end
    end

    context 'when user is admin of organization where other user is member' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, admin_role)
        organization.assign_role(other_user, user_role)
      end

      it 'permits access' do
        policy = described_class.new(user, other_user)
        expect(policy).to permit(:update)
        expect(policy).to permit(:edit)
      end
    end

    context 'when user cannot update other users' do
      it 'denies access' do
        policy = described_class.new(user, other_user)
        expect(policy).not_to permit(:update)
        expect(policy).not_to permit(:edit)
      end
    end
  end

  describe '#index?' do
    context 'when user is logged in' do
      it 'permits access' do
        expect(described_class.new(user, nil)).to permit(:index)
      end
    end

    context 'when user is not logged in' do
      it 'denies access' do
        expect(described_class.new(nil, nil)).not_to permit(:index)
      end
    end
  end

  describe '#manage_roles?' do
    context 'when user is admin in any organization' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(user, admin_role)
      end

      it 'permits access' do
        expect(described_class.new(user, other_user)).to permit(:manage_roles)
      end
    end

    context 'when user is not admin in any organization' do
      before do
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, user_role)
      end

      it 'denies access' do
        expect(described_class.new(user, other_user)).not_to permit(:manage_roles)
      end
    end
  end

  describe '#promote_to_admin? and #demote_to_user?' do
    context 'when user is admin in any organization' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(user, admin_role)
      end

      it 'permits access' do
        policy = described_class.new(user, other_user)
        expect(policy).to permit(:promote_to_admin)
        expect(policy).to permit(:demote_to_user)
      end
    end

    context 'when user is not system admin' do
      it 'denies access' do
        policy = described_class.new(user, other_user)
        expect(policy).not_to permit(:promote_to_admin)
        expect(policy).not_to permit(:demote_to_user)
      end
    end
  end
end
