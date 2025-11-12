require 'rails_helper'

describe LineAccount, type: :model do
  describe 'validations' do
    subject { build(:line_account) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:line_user_id) }
    it { is_expected.to validate_presence_of(:access_token) }
    it { is_expected.to validate_uniqueness_of(:line_user_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe '#access_token_expired?' do
    it 'returns true when token is expired' do
      line_account = build(:line_account, :expired)
      expect(line_account.access_token_expired?).to be true
    end

    it 'returns false when token is not expired' do
      line_account = build(:line_account)
      expect(line_account.access_token_expired?).to be false
    end

    it 'returns true when token will expire within 1 hour' do
      line_account = build(:line_account, :about_to_expire)
      expect(line_account.access_token_expired?).to be true
    end
  end

  describe '#profile_name' do
    it 'returns the display name from LINE' do
      line_account = build(:line_account, display_name: 'John Doe')
      expect(line_account.profile_name).to eq('John Doe')
    end

    it 'returns user name as fallback' do
      user = build(:user, name: 'Fallback Name')
      line_account = build(:line_account, user: user, display_name: nil)
      expect(line_account.profile_name).to eq('Fallback Name')
    end
  end

  describe '#refresh_token!' do
    let(:line_account) { create(:line_account, :expired) }
    let(:new_access_token) { SecureRandom.hex(32) }
    let(:new_expires_at) { 30.days.from_now }

    context 'when refresh is successful' do
      it 'updates access token' do
        line_account.refresh_token!(new_access_token, new_expires_at)
        expect(line_account.access_token).to eq(new_access_token)
      end

      it 'updates expiration time' do
        line_account.refresh_token!(new_access_token, new_expires_at)
        expect(line_account.expires_at).to be_within(1.second).of(new_expires_at)
      end

      it 'saves the changes' do
        line_account.refresh_token!(new_access_token, new_expires_at)
        reloaded = LineAccount.find(line_account.id)
        expect(reloaded.access_token).to eq(new_access_token)
      end

      it 'returns true' do
        result = line_account.refresh_token!(new_access_token, new_expires_at)
        expect(result).to be true
      end
    end
  end

  describe '#should_refresh_token?' do
    it 'returns true when token expires within 1 hour' do
      line_account = build(:line_account, :about_to_expire)
      expect(line_account.should_refresh_token?).to be true
    end

    it 'returns false when token has more than 1 hour left' do
      line_account = build(:line_account)
      expect(line_account.should_refresh_token?).to be false
    end

    it 'returns true when token is already expired' do
      line_account = build(:line_account, :expired)
      expect(line_account.should_refresh_token?).to be true
    end
  end

  describe '#invalidate!' do
    let(:line_account) { create(:line_account) }

    it 'clears the access token' do
      line_account.invalidate!
      expect(line_account.access_token).to be_nil
    end

    it 'clears the refresh token' do
      line_account.invalidate!
      expect(line_account.refresh_token).to be_nil
    end

    it 'sets expiration to past' do
      line_account.invalidate!
      expect(line_account.expires_at).to be <= Time.current
    end

    it 'saves changes' do
      line_account.invalidate!
      reloaded = LineAccount.find(line_account.id)
      expect(reloaded.access_token).to be_nil
    end
  end

  describe 'cascade delete' do
    let!(:line_account) { create(:line_account) }
    let(:user) { line_account.user }

    it 'deletes LINE account when user is deleted' do
      expect {
        user.destroy
      }.to change(LineAccount, :count).by(-1)
    end

    it 'does not leave orphaned LINE account' do
      line_account_id = line_account.id
      user.destroy
      expect(LineAccount.find_by(id: line_account_id)).to be_nil
    end
  end
end