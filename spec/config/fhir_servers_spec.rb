require 'rails_helper'

RSpec.describe FhirServerRegistry do
  describe '.url_for' do
    context 'when given a valid alias' do
      it 'returns sandbox URL for sandbox alias' do
        expect(FhirServerRegistry.url_for('sandbox')).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
      end

      it 'returns HAPI URL for hapi alias' do
        expect(FhirServerRegistry.url_for('hapi')).to eq('https://hapi.fhir.tw/fhir')
      end

      it 'returns local URL for local alias' do
        expect(FhirServerRegistry.url_for('local')).to eq('http://localhost:8080/fhir')
      end

      it 'handles case insensitivity' do
        expect(FhirServerRegistry.url_for('SANDBOX')).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
        expect(FhirServerRegistry.url_for('HaPi')).to eq('https://hapi.fhir.tw/fhir')
      end

      it 'handles whitespace' do
        expect(FhirServerRegistry.url_for('  sandbox  ')).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
      end
    end

    context 'when given nil or empty' do
      it 'returns default server URL (sandbox)' do
        expect(FhirServerRegistry.url_for(nil)).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
        expect(FhirServerRegistry.url_for('')).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
      end
    end

    context 'when given an invalid alias' do
      it 'raises ArgumentError' do
        expect { FhirServerRegistry.url_for('invalid') }.to raise_error(ArgumentError, /未知的 FHIR 伺服器別名/)
      end
    end
  end

  describe '.server_info' do
    it 'returns complete server information' do
      info = FhirServerRegistry.server_info('sandbox')

      expect(info).to be_a(Hash)
      expect(info[:alias]).to eq('sandbox')
      expect(info[:name]).to eq('台灣 SMART Sandbox')
      expect(info[:description]).to eq('台灣智慧醫療 SMART on FHIR 官方沙箱環境')
      expect(info[:url]).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
      expect(info[:oauth2_enabled]).to be true
    end

    it 'includes oauth2_enabled status' do
      expect(FhirServerRegistry.server_info('hapi')[:oauth2_enabled]).to be false
      expect(FhirServerRegistry.server_info('sandbox')[:oauth2_enabled]).to be true
    end

    context 'when given invalid alias' do
      it 'raises ArgumentError' do
        expect { FhirServerRegistry.server_info('invalid') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.all_servers' do
    it 'returns all server configurations' do
      servers = FhirServerRegistry.all_servers

      expect(servers).to be_a(Hash)
      expect(servers.keys).to include('sandbox', 'hapi', 'local')
      expect(servers['sandbox']).to be_a(Hash)
      expect(servers['sandbox'][:name]).to eq('台灣 SMART Sandbox')
    end

    it 'returns independent copies (not references)' do
      servers1 = FhirServerRegistry.all_servers
      servers2 = FhirServerRegistry.all_servers

      servers1['sandbox'][:name] = 'Modified'

      expect(servers2['sandbox'][:name]).to eq('台灣 SMART Sandbox')
    end
  end

  describe '.aliases' do
    it 'returns list of server aliases' do
      aliases = FhirServerRegistry.aliases

      expect(aliases).to be_a(Array)
      expect(aliases).to include('sandbox', 'hapi', 'local')
    end
  end

  describe '.default_server' do
    it 'returns sandbox as default' do
      expect(FhirServerRegistry.default_server).to eq('sandbox')
    end
  end

  describe '.default_url' do
    it 'returns sandbox URL as default' do
      expect(FhirServerRegistry.default_url).to eq('https://emr-smart.appx.com.tw/v/r4/fhir')
    end
  end

  describe '.valid_alias?' do
    it 'returns true for valid aliases' do
      expect(FhirServerRegistry.valid_alias?('sandbox')).to be true
      expect(FhirServerRegistry.valid_alias?('hapi')).to be true
      expect(FhirServerRegistry.valid_alias?('local')).to be true
    end

    it 'returns false for invalid aliases' do
      expect(FhirServerRegistry.valid_alias?('invalid')).to be false
      expect(FhirServerRegistry.valid_alias?('test')).to be false
    end

    it 'handles case insensitivity' do
      expect(FhirServerRegistry.valid_alias?('SANDBOX')).to be true
      expect(FhirServerRegistry.valid_alias?('HaPi')).to be true
    end

    it 'handles nil and empty string' do
      expect(FhirServerRegistry.valid_alias?(nil)).to be true  # defaults to 'sandbox'
      expect(FhirServerRegistry.valid_alias?('')).to be true
    end
  end

  describe '.normalize_alias' do
    it 'returns lowercase normalized alias' do
      expect(FhirServerRegistry.normalize_alias('SANDBOX')).to eq('sandbox')
      expect(FhirServerRegistry.normalize_alias('HaPi')).to eq('hapi')
    end

    it 'strips whitespace' do
      expect(FhirServerRegistry.normalize_alias('  sandbox  ')).to eq('sandbox')
    end

    it 'defaults to sandbox for nil' do
      expect(FhirServerRegistry.normalize_alias(nil)).to eq('sandbox')
    end

    it 'raises error for invalid alias' do
      expect { FhirServerRegistry.normalize_alias('invalid') }.to raise_error(ArgumentError)
    end
  end
end
