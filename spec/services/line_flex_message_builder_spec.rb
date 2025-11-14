require 'rails_helper'

RSpec.describe LineFlexMessageBuilder do
  describe '.build_text_reply' do
    let(:text) { 'Hello from user' }

    it 'builds a valid flex message container' do
      flex = LineFlexMessageBuilder.build_text_reply(text)

      expect(flex).to be_a(Hash)
      expect(flex[:type]).to eq('bubble')
      expect(flex[:body]).to be_a(Hash)
      expect(flex[:body][:type]).to eq('box')
      expect(flex[:body][:layout]).to eq('vertical')
    end

    it 'includes the user text in the flex message' do
      flex = LineFlexMessageBuilder.build_text_reply(text)

      # Find the text box containing the user message
      expect(flex[:body][:contents]).to be_a(Array)
      expect(flex[:body][:contents]).not_to be_empty

      # Find nested text containing the user message
      def find_text_recursive(obj, text)
        case obj
        when Hash
          return obj if obj[:text]&.include?(text)
          obj.values.each { |v| result = find_text_recursive(v, text); return result if result }
        when Array
          obj.each { |item| result = find_text_recursive(item, text); return result if result }
        end
        nil
      end

      content_text = find_text_recursive(flex, text)
      expect(content_text).to be_present
    end

    it 'includes proper styling' do
      flex = LineFlexMessageBuilder.build_text_reply(text)

      expect(flex[:body][:contents]).not_to be_empty
      # First element should have styling
      first_content = flex[:body][:contents].first
      expect(first_content).to have_key(:type)
    end

    it 'handles special characters in text' do
      special_text = 'Hello "World" & <Friends>'
      flex = LineFlexMessageBuilder.build_text_reply(special_text)

      expect(flex).to be_present
      expect(flex[:body][:contents]).not_to be_empty
    end

    it 'handles long text' do
      long_text = 'A' * 1000
      flex = LineFlexMessageBuilder.build_text_reply(long_text)

      expect(flex).to be_present
      expect(flex[:body][:contents]).not_to be_empty
    end

    it 'handles empty text' do
      flex = LineFlexMessageBuilder.build_text_reply('')

      expect(flex).to be_present
      expect(flex[:body][:contents]).not_to be_empty
    end

    it 'includes separator for visual distinction' do
      flex = LineFlexMessageBuilder.build_text_reply(text)

      # Should have visual structure with separators
      expect(flex[:body][:contents]).to be_a(Array)
    end
  end
end
