require 'rails_helper'

RSpec.describe ApplicationPolicy do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before { Role.default_roles }

  # 自訂的 TestPolicy 以測試基類功能
  class TestPolicy < ApplicationPolicy
    def organization_id
      @organization_id ||= record.id if record.is_a?(Organization)
    end
  end

  describe 'default permissions' do
    let(:policy) { TestPolicy.new(user, organization) }

    it { expect(policy).not_to permit(:index) }
    it { expect(policy).not_to permit(:show) }
    it { expect(policy).not_to permit(:create) }
    it { expect(policy).not_to permit(:update) }
    it { expect(policy).not_to permit(:destroy) }
  end

  describe '#admin?' do
    context 'when user is admin of organization' do
      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(user, admin_role)
      end

      it 'returns true' do
        policy = TestPolicy.new(user, organization)
        expect(policy.admin?).to be_truthy
      end
    end

    context 'when user is not admin' do
      before do
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, user_role)
      end

      it 'returns false' do
        policy = TestPolicy.new(user, organization)
        expect(policy.admin?).to be_falsy
      end
    end

    context 'when user is not in organization' do
      it 'returns false' do
        policy = TestPolicy.new(user, organization)
        expect(policy.admin?).to be_falsy
      end
    end
  end

  describe '#moderator?' do
    context 'when user is moderator of organization' do
      before do
        moderator_role = Role.find_by_name(Role::MODERATOR)
        organization.assign_role(user, moderator_role)
      end

      it 'returns true' do
        policy = TestPolicy.new(user, organization)
        expect(policy.moderator?).to be_truthy
      end
    end

    context 'when user is not moderator' do
      it 'returns false' do
        policy = TestPolicy.new(user, organization)
        expect(policy.moderator?).to be_falsy
      end
    end
  end

  describe '#member?' do
    context 'when user is member of organization' do
      before do
        user_role = Role.find_by_name(Role::USER)
        organization.assign_role(user, user_role)
      end

      it 'returns true' do
        policy = TestPolicy.new(user, organization)
        expect(policy.member?).to be_truthy
      end
    end

    context 'when user is not member of organization' do
      it 'returns false' do
        policy = TestPolicy.new(user, organization)
        expect(policy.member?).to be_falsy
      end
    end
  end
end
