require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:user_roles).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_roles) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    describe 'uniqueness of name' do
      before { create(:role, name: 'admin') }

      it 'does not allow duplicate names' do
        role = build(:role, name: 'admin')
        expect(role).not_to be_valid
      end

      it 'does not allow duplicate names with different cases' do
        role = build(:role, name: 'Admin')
        expect(role).not_to be_valid
      end
    end
  end

  describe 'constants' do
    it 'has ADMIN constant' do
      expect(Role::ADMIN).to eq('admin')
    end

    it 'has USER constant' do
      expect(Role::USER).to eq('user')
    end

    it 'has MODERATOR constant' do
      expect(Role::MODERATOR).to eq('moderator')
    end
  end

  describe '.default_roles' do
    it 'creates default roles if they do not exist' do
      expect { Role.default_roles }.to change(Role, :count).by(3)
    end

    it 'does not create duplicate roles on multiple calls' do
      Role.default_roles
      expect { Role.default_roles }.not_to change(Role, :count)
    end

    it 'creates roles with correct names' do
      Role.default_roles

      expect(Role.pluck(:name).sort).to eq([Role::ADMIN, Role::MODERATOR, Role::USER].sort)
    end
  end

  describe '.find_by_name' do
    before { Role.default_roles }

    it 'finds role by name' do
      admin_role = Role.find_by_name(Role::ADMIN)
      expect(admin_role).to be_present
      expect(admin_role.name).to eq(Role::ADMIN)
    end

    it 'returns nil when role does not exist' do
      expect(Role.find_by_name('invalid_role')).to be_nil
    end
  end
end
