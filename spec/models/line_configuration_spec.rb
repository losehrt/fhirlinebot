require 'rails_helper'

RSpec.describe LineConfiguration, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:channel_id) }
    it { is_expected.to validate_presence_of(:channel_secret) }
    it { is_expected.to validate_presence_of(:redirect_uri) }
    it { is_expected.to validate_presence_of(:name) }

    describe 'channel_id uniqueness' do
      let(:org) { create(:organization) }
      let!(:config1) { create(:line_configuration, organization: org, channel_id: 'UNIQUE_CHANNEL') }

      it 'validates uniqueness of channel_id' do
        config2 = build(:line_configuration, organization: org, channel_id: 'UNIQUE_CHANNEL')
        expect(config2).not_to be_valid
        expect(config2.errors[:channel_id]).to be_present
      end
    end
  end

  describe 'scopes' do
    let(:org) { create(:organization) }
    let!(:active_config) { create(:line_configuration, organization: org, is_active: true) }
    let!(:inactive_config) { create(:line_configuration, organization: org, is_active: false, channel_id: 'INACTIVE_CHANNEL') }
    let!(:default_config) { create(:line_configuration, organization: org, is_default: true, channel_id: 'DEFAULT_CHANNEL') }
    let!(:global_config) { create(:line_configuration, organization: nil, is_default: true, channel_id: 'GLOBAL_CHANNEL') }

    describe '.active' do
      it 'returns only active configurations' do
        expect(LineConfiguration.active).to include(active_config, default_config, global_config)
        expect(LineConfiguration.active).not_to include(inactive_config)
      end
    end

    describe '.inactive' do
      it 'returns only inactive configurations' do
        expect(LineConfiguration.inactive).to contain_exactly(inactive_config)
      end
    end

    describe '.by_organization' do
      it 'returns configurations for specific organization' do
        expect(LineConfiguration.by_organization(org.id)).to include(active_config, inactive_config, default_config)
        expect(LineConfiguration.by_organization(org.id)).not_to include(global_config)
      end
    end

    describe '.global' do
      it 'returns only global configurations' do
        expect(LineConfiguration.global).to contain_exactly(global_config)
      end
    end

    describe '.default_config' do
      it 'returns only default configurations' do
        expect(LineConfiguration.default_config).to include(default_config, global_config)
      end
    end
  end

  describe 'class methods' do
    let(:org1) { create(:organization, name: 'Hospital A') }
    let(:org2) { create(:organization, name: 'Hospital B') }
    let!(:org1_config) { create(:line_configuration, organization: org1, channel_id: 'ORG1_CHANNEL', is_default: true) }
    let!(:org2_config) { create(:line_configuration, organization: org2, channel_id: 'ORG2_CHANNEL', is_default: true) }
    let!(:global_config) { create(:line_configuration, organization: nil, channel_id: 'GLOBAL_CHANNEL', is_default: true) }

    describe '.for_organization' do
      context 'when organization has a configuration' do
        it 'returns organization-specific default config' do
          config = LineConfiguration.for_organization(org1.id)
          expect(config).to eq(org1_config)
        end
      end

      context 'when organization has no configuration' do
        it 'returns global default config' do
          other_org = create(:organization)
          config = LineConfiguration.for_organization(other_org.id)
          expect(config).to eq(global_config)
        end
      end

      context 'when requesting global configuration' do
        it 'returns global default config' do
          config = LineConfiguration.for_organization(nil)
          expect(config).to eq(global_config)
        end
      end
    end

    describe '.global_default' do
      it 'returns the global default configuration' do
        config = LineConfiguration.global_default
        expect(config).to eq(global_config)
      end
    end

    describe '.active_for_organization' do
      let!(:inactive_config) { create(:line_configuration, organization: org1, channel_id: 'INACTIVE', is_active: false) }

      it 'returns only active configurations for organization' do
        configs = LineConfiguration.active_for_organization(org1.id)
        expect(configs).to include(org1_config)
        expect(configs).not_to include(inactive_config)
      end

      it 'returns only active global configurations' do
        create(:line_configuration, organization: nil, channel_id: 'GLOBAL_INACTIVE', is_active: false)
        configs = LineConfiguration.active_for_organization(nil)
        expect(configs).to include(global_config)
        expect(configs).not_to include(LineConfiguration.find_by(channel_id: 'GLOBAL_INACTIVE'))
      end
    end
  end

  describe 'instance methods' do
    let(:org) { create(:organization) }
    let!(:config1) { create(:line_configuration, organization: org, channel_id: 'CHANNEL1', is_default: true) }
    let!(:config2) { create(:line_configuration, organization: org, channel_id: 'CHANNEL2', is_default: false) }

    describe '#mark_as_default!' do
      it 'sets the configuration as default' do
        config2.mark_as_default!
        expect(config2.reload.is_default).to be true
      end

      it 'unsets other default configurations in the same organization' do
        config2.mark_as_default!
        expect(config1.reload.is_default).to be false
      end

      it 'only affects configurations in the same organization' do
        other_org = create(:organization)
        other_config = create(:line_configuration, organization: other_org, channel_id: 'OTHER', is_default: true)

        config2.mark_as_default!

        expect(other_config.reload.is_default).to be true
      end
    end

    describe '#deactivate!' do
      it 'sets is_active to false' do
        config1.deactivate!
        expect(config1.reload.is_active).to be false
      end
    end

    describe '#activate!' do
      before { config1.update(is_active: false) }

      it 'sets is_active to true' do
        config1.activate!
        expect(config1.reload.is_active).to be true
      end
    end

    describe '#touch_last_used!' do
      it 'updates last_used_at to current time' do
        before_touch = Time.current
        config1.touch_last_used!
        after_touch = Time.current

        expect(config1.reload.last_used_at).to be_between(before_touch, after_touch)
      end
    end

    describe '#can_delete?' do
      context 'when configuration is not default' do
        it 'returns true' do
          expect(config2.can_delete?).to be true
        end
      end

      context 'when configuration is default' do
        it 'returns false' do
          expect(config1.can_delete?).to be false
        end
      end
    end
  end

  describe 'callbacks' do
    let(:org) { create(:organization) }

    describe 'ensure_single_default_per_organization' do
      it 'enforces only one default configuration per organization' do
        config1 = create(:line_configuration, organization: org, channel_id: 'CH1', is_default: true)
        config2 = create(:line_configuration, organization: org, channel_id: 'CH2', is_default: true)

        expect(config1.reload.is_default).to be false
        expect(config2.reload.is_default).to be true
      end

      it 'does not affect other organizations' do
        org2 = create(:organization)
        config1_org1 = create(:line_configuration, organization: org, channel_id: 'CH1', is_default: true)
        config1_org2 = create(:line_configuration, organization: org2, channel_id: 'CH2', is_default: true)

        config2_org1 = create(:line_configuration, organization: org, channel_id: 'CH3', is_default: true)

        expect(config1_org1.reload.is_default).to be false
        expect(config1_org2.reload.is_default).to be true
      end

      it 'does not affect global configurations' do
        global_config = create(:line_configuration, organization: nil, channel_id: 'GLOBAL', is_default: true)
        org_config = create(:line_configuration, organization: org, channel_id: 'ORG', is_default: true)

        expect(global_config.reload.is_default).to be true
        expect(org_config.reload.is_default).to be true
      end
    end
  end
end
