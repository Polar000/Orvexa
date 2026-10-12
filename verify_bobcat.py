from playwright.sync_api import sync_playwright
import os

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1440, "height": 1000})
    page.goto("http://localhost:3000")
    page.wait_for_timeout(2000)

    # Scroll to Rental section
    rental_heading = page.get_by_text("NEED EQUIPMENT?")
    rental_heading.scroll_into_view_if_needed()
    page.wait_for_timeout(1000)

    os.makedirs("/home/jules/verification", exist_ok=True)
    screenshot_path = "/home/jules/verification/bobcat_fixed.png"
    page.screenshot(path=screenshot_path)
    print("Screenshot saved to:", screenshot_path)
    browser.close()
