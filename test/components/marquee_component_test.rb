require "test_helper"

class MarqueeComponentTest < ViewComponent::TestCase
  def setup
    @announcements = [
      { text: "FHIR LINE Bot 平台正式上線", type: "success" },
      { text: "支援即時醫療資料查詢", type: "info" },
      { text: "已整合多家醫療院所", type: "primary" }
    ]
  end

  test "renders marquee component with announcements" do
    component = MarqueeComponent.new(announcements: @announcements)

    render_inline(component)

    assert_selector "[data-controller='marquee']"
    assert_selector ".marquee-content"

    @announcements.each do |announcement|
      assert_text announcement[:text]
    end
  end

  test "renders with custom speed" do
    component = MarqueeComponent.new(
      announcements: @announcements,
      speed: 100
    )

    render_inline(component)

    assert_selector "[data-marquee-speed-value='100']"
  end

  test "renders with custom direction" do
    component = MarqueeComponent.new(
      announcements: @announcements,
      direction: "right"
    )

    render_inline(component)

    assert_selector "[data-marquee-direction-value='right']"
  end

  test "renders with pause on hover option" do
    component = MarqueeComponent.new(
      announcements: @announcements,
      pause_on_hover: true
    )

    render_inline(component)

    assert_selector "[data-marquee-pause-on-hover-value='true']"
  end

  test "renders empty state when no announcements" do
    component = MarqueeComponent.new(announcements: [])

    render_inline(component)

    assert_no_selector "[data-controller='marquee']"
  end

  test "renders with custom CSS classes" do
    component = MarqueeComponent.new(
      announcements: @announcements,
      class: "custom-marquee"
    )

    render_inline(component)

    assert_selector ".custom-marquee"
  end
end