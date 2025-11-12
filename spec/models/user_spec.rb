require 'rails_helper'

describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to allow_value('user@example.com').for(:email) }
    it { is_expected.not_to allow_value('invalid-email').for(:email) }
  end

  describe 'associations' do
    it { is_expected.to have_one(:line_account).dependent(:destroy) }
  end

  describe '#display_name' do
    it 'returns the user name' do
      user = build(:user, name: 'John Doe')
      expect(user.display_name).to eq('John Doe')
    end

    it 'returns name from LINE account if available' do
      user = build(:user, :with_line_account, name: 'John')
      user.line_account.display_name = 'LINE Name'
      expect(user.display_name).to eq('LINE Name')
    end
  end

  describe '#has_line_account?' do
    it 'returns true when user has LINE account' do
      user = create(:user, :with_line_account)
      expect(user.has_line_account?).to be true
    end

    it 'returns false when user has no LINE account' do
      user = create(:user)
      expect(user.has_line_account?).to be false
    end
  end

  describe '.with_line_account' do
    it 'returns only users with LINE accounts' do
      user_with_line = create(:user, :with_line_account)
      user_without_line = create(:user)

      expect(User.with_line_account).to include(user_with_line)
      expect(User.with_line_account).not_to include(user_without_line)
    end
  end

  describe '.without_line_account' do
    it 'returns only users without LINE accounts' do
      user_with_line = create(:user, :with_line_account)
      user_without_line = create(:user)

      expect(User.without_line_account).to include(user_without_line)
      expect(User.without_line_account).not_to include(user_with_line)
    end
  end

  describe '.find_or_create_from_line' do
    let(:line_user_id) { SecureRandom.uuid }
    let(:line_data) do
      {
        userId: line_user_id,
        displayName: 'LINE User',
        pictureUrl: 'https://example.com/pic.jpg'
      }
    end

    context 'when user does not exist' do
      it 'creates a new user with LINE account' do
        expect {
          User.find_or_create_from_line(line_user_id, line_data)
        }.to change(User, :count).by(1)
          .and change(LineAccount, :count).by(1)
      end

      it 'sets correct user attributes' do
        user = User.find_or_create_from_line(line_user_id, line_data)
        expect(user.name).to eq('LINE User')
        expect(user.email).to match(/@line\.example\.com\z/)
      end

      it 'sets correct LINE account attributes' do
        user = User.find_or_create_from_line(line_user_id, line_data)
        expect(user.line_account.line_user_id).to eq(line_user_id)
        expect(user.line_account.display_name).to eq('LINE User')
        expect(user.line_account.picture_url).to eq('https://example.com/pic.jpg')
      end
    end

    context 'when user with LINE account exists' do
      let!(:user) { create(:user, :with_line_account, line_account: create(:line_account, line_user_id: line_user_id)) }

      it 'does not create a new user' do
        expect {
          User.find_or_create_from_line(line_user_id, line_data)
        }.not_to change(User, :count)
      end

      it 'returns the existing user' do
        result = User.find_or_create_from_line(line_user_id, line_data)
        expect(result.id).to eq(user.id)
      end

      it 'updates user information' do
        new_data = line_data.merge(displayName: 'Updated Name')
        User.find_or_create_from_line(line_user_id, new_data)
        expect(user.reload.name).to eq('Updated Name')
      end

      it 'updates LINE account information' do
        new_data = line_data.merge(pictureUrl: 'https://example.com/new.jpg')
        User.find_or_create_from_line(line_user_id, new_data)
        expect(user.line_account.reload.picture_url).to eq('https://example.com/new.jpg')
      end
    end

    context 'when user exists but no LINE account' do
      let(:user) { create(:user, email: "#{line_user_id}@line.example.com") }

      it 'creates LINE account for existing user' do
        expect {
          User.find_or_create_from_line(line_user_id, line_data)
        }.to change(LineAccount, :count).by(1)
          .and not_change(User, :count)
      end

      it 'associates LINE account with existing user' do
        result = User.find_or_create_from_line(line_user_id, line_data)
        expect(result.id).to eq(user.id)
        expect(result.line_account).to be_present
      end
    end
  end

  describe 'security' do
    it 'encrypts password' do
      user = create(:user, password: 'TestPassword123!')
      expect(user.encrypted_password).not_to eq('TestPassword123!')
    end

    it 'validates password confirmation' do
      user = build(:user, password: 'Test123!', password_confirmation: 'Different')
      expect(user).not_to be_valid
    end
  end
end