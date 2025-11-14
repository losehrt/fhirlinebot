require 'rails_helper'

RSpec.describe LineLoginHandler do
  let(:line_channel_id) { 'test_channel_id' }
  let(:line_channel_secret) { 'test_channel_secret' }
  let(:line_user_id) { 'U1234567890abcdef1234567890abcdef' }
  let(:display_name) { 'Test LINE User' }
  let(:picture_url) { 'https://example.com/profile.jpg' }
  let(:access_token) { 'test_access_token' }
  let(:refresh_token) { 'test_refresh_token' }
  let(:expires_in) { 2592000 }
  let(:organization) { create(:organization) }

  before do
    Role.default_roles

    # Mock LINE API responses
    stub_request(:post, "https://api.line.me/oauth2/v2.1/token").
      to_return(
        status: 200,
        body: JSON.generate({
          access_token: access_token,
          token_type: 'Bearer',
          expires_in: expires_in,
          refresh_token: refresh_token,
          scope: 'profile openid'
        }),
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, "https://api.line.me/v2/profile").
      with(headers: { 'Authorization' => "Bearer #{access_token}" }).
      to_return(
        status: 200,
        body: JSON.generate({
          userId: line_user_id,
          displayName: display_name,
          pictureUrl: picture_url
        }),
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#handle_callback with organization' do
    let(:handler) { described_class.new(line_channel_id, line_channel_secret) }

    context 'when first user joins organization' do
      it 'creates user and assigns admin role' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback', organization: organization)

        expect(user).to be_persisted
        expect(user.admin_in_organization?(organization.id)).to be_truthy

        user_role = UserRole.find_by(user: user, organization: organization)
        expect(user_role).to be_present
        expect(user_role.role.name).to eq(Role::ADMIN)
      end

      it 'marks user as organization member' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback', organization: organization)

        expect(user.member_of_organization?(organization.id)).to be_truthy
      end

      it 'makes user an admin of the organization' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback', organization: organization)

        expect(user.admin_in_organization?(organization.id)).to be_truthy
      end
    end

    context 'when subsequent user joins organization' do
      let!(:admin_user) { create(:user, :with_line_account) }

      before do
        admin_role = Role.find_by_name(Role::ADMIN)
        organization.assign_role(admin_user, admin_role)
      end

      it 'creates user and assigns user role' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback', organization: organization)

        expect(user).to be_persisted
        expect(user.member_of_organization?(organization.id)).to be_truthy

        user_role = UserRole.find_by(user: user, organization: organization)
        expect(user_role).to be_present
        expect(user_role.role.name).to eq(Role::USER)
      end

      it 'does not make the new user an admin' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback', organization: organization)

        expect(user.admin_in_organization?(organization.id)).to be_falsy
      end
    end

    context 'when organization parameter is nil' do
      it 'returns user without organization assignment' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback', organization: nil)

        expect(user).to be_persisted
        expect(user.organizations.count).to eq(0)
      end

      it 'does not assign user to any organization' do
        user = handler.handle_callback('auth_code', 'https://example.com/callback')

        expect(user.organizations.count).to eq(0)
      end
    end
  end
end
