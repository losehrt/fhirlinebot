require 'rails_helper'

RSpec.describe FhirConfiguration, type: :model do
  let(:organization) { create(:organization) }

  describe 'associations' do
    it { is_expected.to belong_to(:organization) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:server_url) }
    it { is_expected.to validate_presence_of(:organization_id) }

    it 'validates server_url is a valid URL' do
      config = build(:fhir_configuration, organization: organization, server_url: 'invalid-url')
      expect(config).not_to be_valid
      expect(config.errors[:server_url]).to be_present
    end
  end

  describe '.for_organization' do
    let!(:config) { create(:fhir_configuration, organization: organization, is_active: true) }

    it 'returns active configuration for the organization' do
      result = FhirConfiguration.for_organization(organization.id)
      expect(result).to eq(config)
    end

    it 'returns nil when no active configuration exists' do
      config.update(is_active: false)
      result = FhirConfiguration.for_organization(organization.id)
      expect(result).to be_nil
    end

    it 'returns nil for invalid organization_id' do
      result = FhirConfiguration.for_organization(nil)
      expect(result).to be_nil
    end
  end

  describe 'scopes' do
    let!(:active_config) { create(:fhir_configuration, organization: organization, is_active: true) }
    let!(:inactive_config) { create(:fhir_configuration, organization: organization, is_active: false) }

    describe '.active' do
      it 'returns only active configurations' do
        expect(FhirConfiguration.active).to include(active_config)
        expect(FhirConfiguration.active).not_to include(inactive_config)
      end
    end
  end

  describe '#validate_connection!' do
    let(:config) { create(:fhir_configuration, organization: organization) }
    let(:client_double) { double }
    let(:response_double) { double(code: '200') }

    before do
      allow(FHIR::Client).to receive(:new).with(config.server_url).and_return(client_double)
      allow(client_double).to receive(:client).and_return(client_double)
    end

    it 'returns true on successful connection' do
      allow(client_double).to receive(:get).with('metadata').and_return(response_double)

      result = config.validate_connection!

      expect(result).to be_truthy
      expect(config.reload.last_validated_at).not_to be_nil
    end

    it 'returns false on failed connection' do
      allow(client_double).to receive(:get).with('metadata').and_return(double(code: '500'))

      result = config.validate_connection!

      expect(result).to be_falsy
    end

    it 'returns false on network error' do
      allow(client_double).to receive(:get).with('metadata').and_raise(Timeout::Error)

      result = config.validate_connection!

      expect(result).to be_falsy
    end

    it 'updates last_validated_at on success' do
      allow(client_double).to receive(:get).with('metadata').and_return(response_double)

      expect {
        config.validate_connection!
      }.to change { config.last_validated_at }
    end
  end
end
