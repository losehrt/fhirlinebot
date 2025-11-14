require 'rails_helper'

RSpec.describe LineLoginHandler, type: :service do
  describe 'initialization with database credentials' do
    # Clear ENV variables for these tests
    around(:each) do |example|
      original_channel_id = ENV['LINE_LOGIN_CHANNEL_ID']
      original_channel_secret = ENV['LINE_LOGIN_CHANNEL_SECRET']

      ENV['LINE_LOGIN_CHANNEL_ID'] = nil
      ENV['LINE_LOGIN_CHANNEL_SECRET'] = nil

      example.run

      ENV['LINE_LOGIN_CHANNEL_ID'] = original_channel_id
      ENV['LINE_LOGIN_CHANNEL_SECRET'] = original_channel_secret
    end

    context 'when database configuration exists' do
      let!(:db_config) do
        create(:line_configuration,
               channel_id: 'DB_CHANNEL_ID',
               channel_secret: 'DB_CHANNEL_SECRET',
               organization_id: nil,
               is_default: true,
               is_active: true)
      end

      it 'loads credentials from database when ENV is not set' do
        handler = LineLoginHandler.new

        expect(handler.instance_variable_get(:@channel_id)).to eq('DB_CHANNEL_ID')
        expect(handler.instance_variable_get(:@channel_secret)).to eq('DB_CHANNEL_SECRET')
      end

      it 'accepts organization_id parameter for multi-tenant support' do
        org = create(:organization)
        org_config = create(:line_configuration,
                           organization: org,
                           channel_id: 'ORG_CHANNEL_ID',
                           channel_secret: 'ORG_CHANNEL_SECRET',
                           is_default: true,
                           is_active: true)

        handler = LineLoginHandler.new(organization_id: org.id)

        expect(handler.instance_variable_get(:@channel_id)).to eq('ORG_CHANNEL_ID')
        expect(handler.instance_variable_get(:@channel_secret)).to eq('ORG_CHANNEL_SECRET')
      end

      it 'falls back to global config when organization has no config' do
        org = create(:organization)

        handler = LineLoginHandler.new(organization_id: org.id)

        expect(handler.instance_variable_get(:@channel_id)).to eq('DB_CHANNEL_ID')
        expect(handler.instance_variable_get(:@channel_secret)).to eq('DB_CHANNEL_SECRET')
      end
    end

    context 'when no database configuration exists' do
      it 'raises error with clear message' do
        # Note: This test will only work if LINE_LOGIN_CHANNEL_ID ENV is not set
        # In test environments where it IS set, it will use the ENV value
        # This is expected behavior per the priority system (ENV > DB)
        if ENV['LINE_LOGIN_CHANNEL_ID'].blank?
          expect {
            LineLoginHandler.new
          }.to raise_error(/LINE_LOGIN_CHANNEL_ID not configured/)
        else
          # If ENV is set, we expect the handler to initialize successfully
          # using the ENV value (which is the correct priority behavior)
          expect {
            LineLoginHandler.new
          }.not_to raise_error
        end
      end
    end

    context 'when explicit credentials are provided' do
      it 'uses explicit credentials over database' do
        create(:line_configuration,
               channel_id: 'DB_CHANNEL_ID',
               channel_secret: 'DB_CHANNEL_SECRET',
               organization_id: nil,
               is_default: true,
               is_active: true)

        handler = LineLoginHandler.new('EXPLICIT_ID', 'EXPLICIT_SECRET')

        expect(handler.instance_variable_get(:@channel_id)).to eq('EXPLICIT_ID')
        expect(handler.instance_variable_get(:@channel_secret)).to eq('EXPLICIT_SECRET')
      end
    end

    context 'cache invalidation' do
      let!(:db_config) do
        create(:line_configuration,
               channel_id: 'INITIAL_ID',
               channel_secret: 'INITIAL_SECRET',
               organization_id: nil,
               is_default: true,
               is_active: true)
      end

      it 'reflects updated credentials after database change' do
        # Create first handler with initial credentials
        handler1 = LineLoginHandler.new

        expect(handler1.instance_variable_get(:@channel_id)).to eq('INITIAL_ID')

        # Update the database configuration
        db_config.update(channel_id: 'UPDATED_ID', channel_secret: 'UPDATED_SECRET')

        # Cache should be invalidated, so new handler gets new credentials
        handler2 = LineLoginHandler.new

        expect(handler2.instance_variable_get(:@channel_id)).to eq('UPDATED_ID')
        expect(handler2.instance_variable_get(:@channel_secret)).to eq('UPDATED_SECRET')
      end

      it 'reflects changes when configuration is deactivated and reactivated' do
        handler1 = LineLoginHandler.new

        # Deactivate the configuration
        db_config.deactivate!

        # Should raise error since no active config exists
        expect {
          LineLoginHandler.new
        }.to raise_error(/LINE_LOGIN_CHANNEL_ID not configured/)

        # Reactivate the configuration
        db_config.activate!

        # Should work again
        handler3 = LineLoginHandler.new
        expect(handler3.instance_variable_get(:@channel_id)).to eq('INITIAL_ID')
      end
    end

    context 'priority system' do
      let!(:db_config) do
        create(:line_configuration,
               channel_id: 'DB_CHANNEL_ID',
               channel_secret: 'DB_CHANNEL_SECRET',
               organization_id: nil,
               is_default: true,
               is_active: true)
      end

      it 'prioritizes ENV over database when both exist' do
        ENV['LINE_LOGIN_CHANNEL_ID'] = 'ENV_CHANNEL_ID'
        ENV['LINE_LOGIN_CHANNEL_SECRET'] = 'ENV_CHANNEL_SECRET'

        handler = LineLoginHandler.new

        expect(handler.instance_variable_get(:@channel_id)).to eq('ENV_CHANNEL_ID')
        expect(handler.instance_variable_get(:@channel_secret)).to eq('ENV_CHANNEL_SECRET')
      end

      it 'prioritizes explicit params over everything' do
        ENV['LINE_LOGIN_CHANNEL_ID'] = 'ENV_CHANNEL_ID'
        ENV['LINE_LOGIN_CHANNEL_SECRET'] = 'ENV_CHANNEL_SECRET'

        handler = LineLoginHandler.new('EXPLICIT_ID', 'EXPLICIT_SECRET')

        expect(handler.instance_variable_get(:@channel_id)).to eq('EXPLICIT_ID')
        expect(handler.instance_variable_get(:@channel_secret)).to eq('EXPLICIT_SECRET')
      end
    end
  end

  describe 'multi-tenant support' do
    let(:org1) { create(:organization, name: 'Hospital A') }
    let(:org2) { create(:organization, name: 'Hospital B') }

    let!(:org1_config) do
      create(:line_configuration,
             organization: org1,
             channel_id: 'ORG1_CHANNEL',
             channel_secret: 'ORG1_SECRET',
             is_default: true,
             is_active: true)
    end

    let!(:org2_config) do
      create(:line_configuration,
             organization: org2,
             channel_id: 'ORG2_CHANNEL',
             channel_secret: 'ORG2_SECRET',
             is_default: true,
             is_active: true)
    end

    around(:each) do |example|
      original_channel_id = ENV['LINE_LOGIN_CHANNEL_ID']
      original_channel_secret = ENV['LINE_LOGIN_CHANNEL_SECRET']

      ENV['LINE_LOGIN_CHANNEL_ID'] = nil
      ENV['LINE_LOGIN_CHANNEL_SECRET'] = nil

      example.run

      ENV['LINE_LOGIN_CHANNEL_ID'] = original_channel_id
      ENV['LINE_LOGIN_CHANNEL_SECRET'] = original_channel_secret
    end

    it 'uses organization-specific credentials' do
      handler1 = LineLoginHandler.new(organization_id: org1.id)
      handler2 = LineLoginHandler.new(organization_id: org2.id)

      expect(handler1.instance_variable_get(:@channel_id)).to eq('ORG1_CHANNEL')
      expect(handler2.instance_variable_get(:@channel_id)).to eq('ORG2_CHANNEL')
    end

    it 'isolates credentials between organizations' do
      config1 = handler1 = LineLoginHandler.new(organization_id: org1.id)
      config2 = handler2 = LineLoginHandler.new(organization_id: org2.id)

      expect(handler1.instance_variable_get(:@channel_id)).not_to eq(
        handler2.instance_variable_get(:@channel_id)
      )
    end
  end
end
