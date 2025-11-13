require "application_system_test_case"

class MarqueeTest < ApplicationSystemTestCase
  test "displays marquee with announcements on homepage" do
    visit root_path

    # 檢查跑馬燈容器存在
    assert_selector "[data-controller='marquee']"
    assert_selector ".marquee-track"
    assert_selector ".marquee-content"

    # 檢查跑馬燈內容
    within "[data-controller='marquee']" do
      assert_text "FHIR LINE Bot 平台正式上線"
      assert_text "已整合超過 10 家醫療院所"
      assert_text "符合 FHIR R4 國際標準"
      assert_text "支援即時醫療資料查詢"
    end
  end

  test "marquee has correct data attributes" do
    visit root_path

    marquee = find("[data-controller='marquee']")

    # 檢查 data attributes
    assert_equal "20", marquee["data-marquee-speed-value"]
    assert_equal "0", marquee["data-marquee-hover-speed-value"]
    assert_equal "left", marquee["data-marquee-direction-value"]
  end

  test "marquee clones content for seamless loop" do
    visit root_path

    # 使用 JavaScript 檢查是否有複製內容
    clones_count = page.evaluate_script(
      "document.querySelectorAll('.marquee-content').length"
    )

    assert clones_count > 1, "應該要有複製的內容以實現無縫循環"
  end

  test "marquee has animation applied" do
    visit root_path

    # 檢查動畫是否套用
    has_animation = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.marquee-track')).animation !== 'none'"
    )

    assert has_animation, "跑馬燈應該要有動畫效果"
  end
end