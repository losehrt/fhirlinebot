class HealthiconsDemoController < ApplicationController
  skip_before_action :require_setup_completion  # Allow access without setup
  layout 'flexy'  # Use Flexy layout

  def index
    # Load metadata for better organization
    metadata_path = Rails.root.join('vendor', 'javascript', 'healthicons', 'public', 'icons', 'meta-data.json')
    if File.exist?(metadata_path)
      @metadata = JSON.parse(File.read(metadata_path))
    end

    # Common medical icons for quick access
    @common_icons = [
      { category: 'body', name: 'heart', label: '心臟' },
      { category: 'body', name: 'lungs', label: '肺部' },
      { category: 'body', name: 'stomach', label: '胃' },
      { category: 'devices', name: 'stethoscope', label: '聽診器' },
      { category: 'devices', name: 'thermometer', label: '體溫計' },
      { category: 'devices', name: 'blood_pressure_monitor', label: '血壓計' },
      { category: 'medications', name: 'medicines', label: '藥品' },
      { category: 'medications', name: 'pills_1', label: '藥丸' },
      { category: 'medications', name: 'syringe', label: '注射器' },
      { category: 'people', name: 'doctor_male', label: '男醫師' },
      { category: 'people', name: 'doctor_female', label: '女醫師' },
      { category: 'people', name: 'nurse_male', label: '男護士' },
      { category: 'places', name: 'hospital', label: '醫院' },
      { category: 'places', name: 'pharmacy', label: '藥房' },
      { category: 'places', name: 'emergency', label: '急診室' }
    ]

    # Emotion icons for mental health
    @emotion_icons = [
      { category: 'emotions', name: 'happy', label: '開心' },
      { category: 'emotions', name: 'sad', label: '悲傷' },
      { category: 'emotions', name: 'angry', label: '生氣' },
      { category: 'emotions', name: 'anxious', label: '焦慮' },
      { category: 'emotions', name: 'calm', label: '平靜' },
      { category: 'emotions', name: 'confused', label: '困惑' }
    ]

    # Blood type icons
    @blood_icons = [
      { category: 'blood', name: 'blood_a_p', label: 'A+' },
      { category: 'blood', name: 'blood_a_n', label: 'A-' },
      { category: 'blood', name: 'blood_b_p', label: 'B+' },
      { category: 'blood', name: 'blood_b_n', label: 'B-' },
      { category: 'blood', name: 'blood_ab_p', label: 'AB+' },
      { category: 'blood', name: 'blood_ab_n', label: 'AB-' },
      { category: 'blood', name: 'blood_o_p', label: 'O+' },
      { category: 'blood', name: 'blood_o_n', label: 'O-' }
    ]

    # Get all available categories
    @categories = view_context.healthicon_categories
  end
end