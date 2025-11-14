require 'rails_helper'

RSpec.describe LineConfig, type: :model do
  # Mock credentials globally to prevent real credentials from interfering with tests
  # Returns nil for all dig calls, simulating empty credentials
  before do
    unless @credentials_mocked
      allow(Rails.application).to receive(:credentials).and_wrap_original do |method, *args|
        double(dig: nil, present?: false)
      end
      @credentials_mocked = true
    end
  end

  describe '.channel_id' do
    context 'when environment variable is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return('ENV_CHANNEL_ID')
      end

      it 'returns environment variable value' do
        LineConfig.refresh!
        expect(LineConfig.channel_id).to eq('ENV_CHANNEL_ID')
      end
    end

    context 'when environment variable is not set but database config exists' do
      let!(:config) { create(:line_configuration, organization: nil, channel_id: 'DB_CHANNEL_ID', is_default: true) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
      end

      it 'returns database configuration' do
        LineConfig.refresh!
        result = LineConfig.channel_id
        expect(result).to eq('DB_CHANNEL_ID')
      end

      context 'with organization_id parameter' do
        let(:org) { create(:organization) }
        let!(:org_config) { create(:line_configuration, organization: org, channel_id: 'ORG_CHANNEL_ID', is_default: true) }

        it 'returns organization-specific configuration' do
          LineConfig.refresh!
          result = LineConfig.channel_id(organization_id: org.id)
          expect(result).to eq('ORG_CHANNEL_ID')
        end
      end
    end

    context 'when neither environment nor database config exists' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
      end

      it 'raises an error' do
        LineConfig.refresh!
        expect do
          LineConfig.channel_id
        end.to raise_error(RuntimeError, /LINE_LOGIN_CHANNEL_ID not configured/)
      end
    end
  end

  describe '.channel_secret' do
    context 'when environment variable is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return('ENV_SECRET')
      end

      it 'returns environment variable value' do
        LineConfig.refresh!
        expect(LineConfig.channel_secret).to eq('ENV_SECRET')
      end
    end

    context 'when database config exists' do
      let!(:config) { create(:line_configuration, organization: nil, channel_secret: 'DB_SECRET', is_default: true) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
      end

      it 'returns database configuration' do
        LineConfig.refresh!
        result = LineConfig.channel_secret
        expect(result).to eq('DB_SECRET')
      end

      context 'with organization_id parameter' do
        let(:org) { create(:organization) }
        let!(:org_config) { create(:line_configuration, organization: org, channel_secret: 'ORG_SECRET', is_default: true) }

        it 'returns organization-specific configuration' do
          LineConfig.refresh!
          result = LineConfig.channel_secret(organization_id: org.id)
          expect(result).to eq('ORG_SECRET')
        end
      end
    end
  end

  describe '.access_token' do
    context 'when environment variable is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return('ENV_ACCESS_TOKEN')
      end

      it 'returns environment variable value' do
        LineConfig.refresh!
        expect(LineConfig.access_token).to eq('ENV_ACCESS_TOKEN')
      end
    end

    context 'when database config exists' do
      let!(:config) { create(:line_configuration, organization: nil, access_token: 'DB_ACCESS_TOKEN', is_default: true) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
      end

      it 'returns database configuration' do
        LineConfig.refresh!
        result = LineConfig.access_token
        expect(result).to eq('DB_ACCESS_TOKEN')
      end

      context 'with organization_id parameter' do
        let(:org) { create(:organization) }
        let!(:org_config) { create(:line_configuration, organization: org, access_token: 'ORG_ACCESS_TOKEN', is_default: true) }

        it 'returns organization-specific configuration' do
          LineConfig.refresh!
          result = LineConfig.access_token(organization_id: org.id)
          expect(result).to eq('ORG_ACCESS_TOKEN')
        end
      end
    end

    context 'when neither environment nor database config exists' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_CHANNEL_ACCESS_TOKEN').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
      end

      it 'returns nil' do
        LineConfig.refresh!
        expect(LineConfig.access_token).to be_nil
      end
    end
  end

  describe '.redirect_uri' do
    context 'when environment variable is set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return('https://custom.com/callback')
      end

      it 'returns environment variable value' do
        expect(LineConfig.redirect_uri).to eq('https://custom.com/callback')
      end
    end

    context 'when environment variable is not set' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
        allow(ENV).to receive(:[]).with('APP_URL').and_return(nil)
      end

      it 'returns default redirect URI' do
        uri = LineConfig.redirect_uri
        expect(uri).to match(/\/auth\/line\/callback$/)
      end
    end
  end

  describe '.config' do
    let!(:config) { create(:line_configuration, organization: nil, channel_id: 'TEST_CHANNEL', channel_secret: 'TEST_SECRET', redirect_uri: 'https://test.com/callback', is_default: true) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
      allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
      allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
    end

    it 'returns a hash with all configuration values' do
      LineConfig.refresh!
      result = LineConfig.config
      expect(result).to be_a(Hash)
      expect(result).to have_key(:channel_id)
      expect(result).to have_key(:channel_secret)
      expect(result).to have_key(:redirect_uri)
    end

    context 'with organization_id parameter' do
      let(:org) { create(:organization) }
      let!(:org_config) { create(:line_configuration, organization: org, channel_id: 'ORG_CHANNEL', channel_secret: 'ORG_SECRET', is_default: true) }

      it 'includes organization-specific configuration when organization_id is provided' do
        LineConfig.refresh!
        result = LineConfig.config(organization_id: org.id)
        expect(result[:channel_id]).to eq('ORG_CHANNEL')
        expect(result[:channel_secret]).to eq('ORG_SECRET')
      end
    end
  end

  describe '.configured?' do
    context 'when all required configuration is present' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return('CHANNEL_ID')
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return('SECRET')
      end

      it 'returns true' do
        LineConfig.refresh!
        expect(LineConfig.configured?).to be true
      end
    end

    context 'when configuration is missing' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
        allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
      end

      it 'returns false' do
        LineConfig.refresh!
        expect(LineConfig.configured?).to be false
      end
    end

    context 'with organization_id parameter' do
      let(:org) { create(:organization) }

      context 'when organization has configuration' do
        let!(:config) { create(:line_configuration, organization: org, channel_id: 'ORG_CHANNEL', channel_secret: 'ORG_SECRET', is_default: true) }

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
          allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
          allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
        end

        it 'returns true' do
          LineConfig.refresh!
          expect(LineConfig.configured?(organization_id: org.id)).to be true
        end
      end

      context 'when organization has no configuration' do
        let(:org_without_config) { create(:organization) }

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
          allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
          allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
        end

        it 'returns false' do
          LineConfig.refresh!
          expect(LineConfig.configured?(organization_id: org_without_config.id)).to be false
        end
      end
    end
  end

  describe '.refresh!' do
    let(:org) { create(:organization) }
    let!(:config) { create(:line_configuration, organization: org, channel_id: 'CACHED_CHANNEL', is_default: true) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
      allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
      allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
    end

    it 'clears the configuration cache' do
      LineConfig.refresh!
      LineConfig.channel_id(organization_id: org.id)

      # Update configuration
      config.update(channel_id: 'UPDATED_CHANNEL')

      # Without refresh, would return cached value
      LineConfig.refresh!

      expect(LineConfig.channel_id(organization_id: org.id)).to eq('UPDATED_CHANNEL')
    end
  end

  describe 'caching behavior' do
    let(:org) { create(:organization) }
    let!(:config) { create(:line_configuration, organization: org, channel_id: 'CACHED_CHANNEL', channel_secret: 'CACHED_SECRET', is_default: true) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_ID').and_return(nil)
      allow(ENV).to receive(:[]).with('LINE_LOGIN_CHANNEL_SECRET').and_return(nil)
      allow(ENV).to receive(:[]).with('LINE_LOGIN_REDIRECT_URI').and_return(nil)
    end

    it 'caches configuration values' do
      LineConfig.refresh!

      # First call should fetch from database and cache it
      result1 = LineConfig.channel_id(organization_id: org.id)
      expect(result1).to eq('CACHED_CHANNEL')

      # Directly update the database record in a new query
      # This ensures the update happens in the database
      LineConfiguration.where(id: config.id).update_all(channel_id: 'NEW_CHANNEL')

      # Second call should return cached value (not the new DB value)
      result2 = LineConfig.channel_id(organization_id: org.id)

      expect(result2).to eq('CACHED_CHANNEL')
    end

    it 'uses separate cache keys for different organizations' do
      org2 = create(:organization)
      config2 = create(:line_configuration, organization: org2, channel_id: 'ORG2_CHANNEL', is_default: true)

      LineConfig.refresh!

      result1 = LineConfig.channel_id(organization_id: org.id)
      result2 = LineConfig.channel_id(organization_id: org2.id)

      expect(result1).to eq('CACHED_CHANNEL')
      expect(result2).to eq('ORG2_CHANNEL')
    end
  end
end
