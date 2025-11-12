# Healthicons Helper
# Provides methods to easily use Healthicons in Rails views
# Icons are available in filled and outline styles
# Documentation: https://github.com/resolvetosavelives/healthicons

module HealthiconsHelper
  # Render a healthicon SVG inline
  #
  # @param category [String] Icon category (e.g., 'body', 'devices', 'blood')
  # @param name [String] Icon name within the category
  # @param style [String] Icon style: 'filled' or 'outline' (default: 'outline')
  # @param size [String] Icon size: 'default' (48px) or '24px' (default: 'default')
  # @param options [Hash] Additional HTML attributes for the SVG element
  #
  # @example Basic usage
  #   <%= healthicon('body', 'heart') %>
  #
  # @example With custom style and size
  #   <%= healthicon('devices', 'stethoscope', style: 'filled', size: '24px') %>
  #
  # @example With custom CSS classes and attributes
  #   <%= healthicon('blood', 'blood_a_p', class: 'text-red-500', data: { tooltip: 'Blood Type A+' }) %>
  #
  def healthicon(category, name, style: 'outline', size: 'default', **options)
    # Determine the correct path
    size_suffix = size == '24px' ? '-24px' : ''
    style_path = "#{style}#{size_suffix}"

    # Build the full path to the SVG file
    svg_path = Rails.root.join(
      'app', 'assets', 'images', 'healthicons', 'svg',
      style_path, category, "#{name}.svg"
    )

    # Check if file exists
    unless File.exist?(svg_path)
      Rails.logger.warn "Healthicon not found: #{svg_path}"
      return content_tag(:span, "[#{category}/#{name}]", class: 'healthicon-missing')
    end

    # Read the SVG content
    svg_content = File.read(svg_path)

    # Parse and modify SVG attributes
    svg_doc = Nokogiri::HTML::DocumentFragment.parse(svg_content)
    svg_element = svg_doc.at_css('svg')

    if svg_element
      # Add custom classes
      if options[:class]
        existing_classes = svg_element['class'] || ''
        svg_element['class'] = "#{existing_classes} #{options[:class]}".strip
        options.delete(:class)
      end

      # Add other attributes
      options.each do |key, value|
        if key.to_s == 'data'
          value.each { |k, v| svg_element["data-#{k}"] = v }
        else
          svg_element[key.to_s] = value.to_s
        end
      end

      # Default size if not specified
      unless svg_element['width'] || svg_element['height']
        default_size = size == '24px' ? '24' : '48'
        svg_element['width'] = default_size
        svg_element['height'] = default_size
      end
    end

    # Return as safe HTML
    svg_doc.to_html.html_safe
  end

  # List all available categories
  def healthicon_categories
    svg_dir = Rails.root.join('app', 'assets', 'images', 'healthicons', 'svg', 'outline')
    return [] unless Dir.exist?(svg_dir)

    Dir.entries(svg_dir)
       .select { |entry| File.directory?(File.join(svg_dir, entry)) }
       .reject { |entry| entry.start_with?('.') }
       .sort
  end

  # List all icons in a category
  def healthicon_list(category, style: 'outline', size: 'default')
    size_suffix = size == '24px' ? '-24px' : ''
    style_path = "#{style}#{size_suffix}"

    icon_dir = Rails.root.join(
      'app', 'assets', 'images', 'healthicons', 'svg',
      style_path, category
    )

    return [] unless Dir.exist?(icon_dir)

    Dir.entries(icon_dir)
       .select { |entry| entry.end_with?('.svg') }
       .map { |entry| entry.sub('.svg', '') }
       .sort
  end

  # Generate icon with text label
  def healthicon_with_label(category, name, label, style: 'outline', size: 'default', **options)
    content_tag :div, class: 'healthicon-container inline-flex items-center gap-2' do
      concat healthicon(category, name, style: style, size: size, **options)
      concat content_tag(:span, label, class: 'healthicon-label')
    end
  end

  # Generate a grid of icons (useful for icon pickers or galleries)
  def healthicon_grid(icons, columns: 4, **icon_options)
    content_tag :div, class: "healthicon-grid grid grid-cols-#{columns} gap-4" do
      icons.each do |icon_data|
        concat(
          content_tag :div, class: 'healthicon-grid-item text-center' do
            if icon_data.is_a?(Hash)
              concat healthicon(icon_data[:category], icon_data[:name], **icon_options)
              concat content_tag(:p, icon_data[:label] || icon_data[:name], class: 'text-xs mt-1')
            else
              # Assume it's a simple [category, name] array
              concat healthicon(icon_data[0], icon_data[1], **icon_options)
              concat content_tag(:p, icon_data[1], class: 'text-xs mt-1')
            end
          end
        )
      end
    end
  end

  # Common healthcare icon shortcuts
  def health_heart_icon(**options)
    healthicon('body', 'heart', **options)
  end

  def health_stethoscope_icon(**options)
    healthicon('devices', 'stethoscope', **options)
  end

  def health_hospital_icon(**options)
    healthicon('places', 'hospital', **options)
  end

  def health_medication_icon(**options)
    healthicon('medications', 'medicines', **options)
  end

  def health_doctor_icon(**options)
    healthicon('people', 'doctor_male', **options)
  end

  def health_patient_icon(**options)
    healthicon('people', 'injured_person', **options)
  end
end