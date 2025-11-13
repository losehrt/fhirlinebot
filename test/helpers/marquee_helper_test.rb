require "test_helper"

class MarqueeHelperTest < ActionView::TestCase
  test "renders marquee with announcements" do
    announcements = [
      { text: "FHIR LINE Bot 平台正式上線", type: "success" },
      { text: "支援即時醫療資料查詢", type: "info" }
    ]

    output = render_marquee(announcements: announcements)

    assert_match /data-controller.*marquee/, output
    assert_match /FHIR LINE Bot 平台正式上線/, output
    assert_match /支援即時醫療資料查詢/, output
  end

  test "renders marquee with custom options" do
    announcements = [{ text: "Test", type: "info" }]

    output = render_marquee(
      announcements: announcements,
      speed: 100,
      direction: "right",
      pause_on_hover: true
    )

    assert_match /data-marquee-speed-value.*100/, output
    assert_match /data-marquee-direction-value.*right/, output
    assert_match /data-marquee-pause-on-hover-value.*true/, output
  end

  test "returns empty string when no announcements" do
    output = render_marquee(announcements: [])
    assert_equal "", output
  end
end