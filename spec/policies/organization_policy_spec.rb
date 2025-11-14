require 'rails_helper'

RSpec.describe OrganizationPolicy do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before { Role.default_roles }

  describe '#show?' do
    context 'when user is member of organization' do
      before do
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, user_role)
      end

      it 'permits access' do
        expect(described_class.new(user, organization)).to permit(:show)
      end
    end

    context 'when user is not member of organization' do
      it 'denies access' do
        expect(described_class.new(user, organization)).not_to permit(:show)
      end
    end
  end

  describe '#edit? and #update?' do
    context 'when user is admin of organization' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(user, admin_role)
      end

      it 'permits access' do
        policy = described_class.new(user, organization)
        expect(policy).to permit(:edit)
        expect(policy).to permit(:update)
      end
    end

    context 'when user is not admin' do
      before do
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, user_role)
      end

      it 'denies access' do
        policy = described_class.new(user, organization)
        expect(policy).not_to permit(:edit)
        expect(policy).not_to permit(:update)
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

  describe '#manage_members? and #manage_roles?' do
    context 'when user is admin of organization' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(user, admin_role)
      end

      it 'permits access' do
        policy = described_class.new(user, organization)
        expect(policy).to permit(:manage_members)
        expect(policy).to permit(:manage_roles)
      end
    end

    context 'when user is not admin' do
      before do
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, user_role)
      end

      it 'denies access' do
        policy = described_class.new(user, organization)
        expect(policy).not_to permit(:manage_members)
        expect(policy).not_to permit(:manage_roles)
      end
    end
  end
end
