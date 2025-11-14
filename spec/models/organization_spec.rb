require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:line_configurations).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#line_configuration' do
    let(:org) { create(:organization) }

    context 'when organization has a default configuration' do
      let!(:default_config) { create(:line_configuration, organization: org, channel_id: 'DEFAULT', is_default: true, is_active: true) }

      it 'returns the default configuration' do
        expect(org.line_configuration).to eq(default_config)
      end
    end

    context 'when organization has no configuration but global default exists' do
      let!(:global_config) { create(:line_configuration, organization: nil, channel_id: 'GLOBAL', is_default: true, is_active: true) }

      it 'returns the global default configuration' do
        expect(org.line_configuration).to eq(global_config)
      end
    end

    context 'when organization has multiple configurations' do
      let!(:backup_config) { create(:line_configuration, organization: org, channel_id: 'BACKUP', is_default: false) }
      let!(:default_config) { create(:line_configuration, organization: org, channel_id: 'DEFAULT', is_default: true) }

      it 'returns only the default configuration' do
        expect(org.line_configuration).to eq(default_config)
      end
    end

    context 'when organization has inactive default configuration' do
      let!(:inactive_config) { create(:line_configuration, organization: org, channel_id: 'INACTIVE', is_default: true, is_active: false) }
      let!(:global_config) { create(:line_configuration, organization: nil, channel_id: 'GLOBAL', is_default: true, is_active: true) }

      it 'returns the global default configuration' do
        expect(org.line_configuration).to eq(global_config)
      end
    end
  end

  describe '#line_configurations_active' do
    let(:org) { create(:organization) }

    it 'returns all active line configurations for the organization' do
      active1 = create(:line_configuration, organization: org, channel_id: 'ACTIVE1', is_active: true)
      active2 = create(:line_configuration, organization: org, channel_id: 'ACTIVE2', is_active: true)
      inactive = create(:line_configuration, organization: org, channel_id: 'INACTIVE', is_active: false)

      configs = org.line_configurations_active

      expect(configs).to include(active1, active2)
      expect(configs).not_to include(inactive)
    end

    it 'does not include global configurations' do
      org_config = create(:line_configuration, organization: org, channel_id: 'ORG', is_active: true)
      global_config = create(:line_configuration, organization: nil, channel_id: 'GLOBAL', is_active: true)

      configs = org.line_configurations_active

      expect(configs).to include(org_config)
      expect(configs).not_to include(global_config)
    end
  end
end
