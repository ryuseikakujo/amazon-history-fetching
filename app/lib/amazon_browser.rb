require 'csv'

class AmazonBrowser
  LOGIN_URL = 'https://www.amazon.co.jp/ap/signin?openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.co.jp%2F%3F%26tag%3Dhydraamazonav-22%26ref%3Dnav_signin%26adgrpid%3D56100363354%26hvpone%3D%26hvptwo%3D%26hvadid%3D289260145877%26hvpos%3D%26hvnetw%3Dg%26hvrand%3D16218428154209222735%26hvqmt%3De%26hvdev%3Dc%26hvdvcmdl%3D%26hvlocint%3D%26hvlocphy%3D1009541%26hvtargid%3Dkwd-10573980%26hydadcr%3D27922_11415158%26gclid%3DCj0KCQjwl4v4BRDaARIsAFjATPk0lSlYv&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=jpflex&openid.mode=checkid_setup&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&'
  
  def self.login
    browser = Watir::Browser.new :chrome, switches: ['--kiosk-printing']
    browser.goto(LOGIN_URL)
    browser.wait
    # browser.text_field(id: 'ap_email').set('ryuseikakujo@gmail.com')
    browser.text_field(id: 'ap_email').set(ENV['EMAIL'])
    browser.element(id: "continue").click
    browser.wait
    browser.checkbox(name: "rememberMe").click
    # browser.text_field(id: 'ap_password').set('zns7j8dW')
    browser.text_field(id: 'ap_password').set(ENV['PASSWORD'])
    browser.element(id: "signInSubmit").click
    browser.wait
  end

  def self.goto_history(browser, year)
    history_url = "https://www.amazon.co.jp/gp/your-account/order-history?opt=ab&digitalOrders=1&unifiedOrders=1&returnTo=&__mk_ja_JP=%E3%82%AB%E3%82%BF%E3%82%AB%E3%83%8A&orderFilter=year-#{year}"
    browser.goto(history_url)
    browser.wait
  end

  def self.scrape_history(browser, array = [])
    page_item_count = browser.divs(class: "a-box-group").count
    for idx in 0..(page_item_count - 1) do
      browser.div(class: "a-box-group", index: idx).scroll.to
      # name = browser.div(class: "a-box-group", index: idx).element(class: "a-box", index: 1).element(class: "a-link-normal", index: 1).text()
      name = browser.div(class: "a-box-group", index: idx).elements(class: "a-box").last.element(class: "a-link-normal", index: 1).text()
      ap name
      # url = browser.div(class: "a-box-group", index: idx).element(class: "a-box", index: 1).a(class: "a-link-normal", index: 1).href
      url = browser.div(class: "a-box-group", index: idx).elements(class: "a-box").last.a(class: "a-link-normal", index: 1).href
      ap url
      purchased_at = browser.div(class: "a-box-group", index: idx).element(class: ["a-color-secondary", "value"], index: 0).text()
      ap purchased_at
      price = browser.div(class: "a-box-group", index: idx).element(class: ["a-color-secondary", "value"], index: 1).text().delete("￥").delete(",").strip
      ap price
      hash = {}
      hash["name"] = name
      hash["url"] = url
      hash["purchased_at"] = purchased_at
      hash["price"] = price
      array << hash
    end
    if browser.element(class: "a-last").a.exists?
      next_url = browser.element(class: "a-last").a.href
      browser.goto(next_url)
      browser.wait
      self.scrape_history(browser, array)
    end
    array
  end


  # csv(もしアマゾンが確認コードを要求してきた場合)
  def self.generate_report(browser)
    array = []
    array.concat(self.scrape_history(browser))
    CSV.open('purchase_items.csv', 'w') do |csv|
      csv << ["購入日", "商品名", "商品URL", "金額"]
      array.each do |item|
        csv << [item["purchased_at"], item["name"], item["url"], item["price"]]
      end
    end
  end

  def self.download_receipt(browser)
    page_item_count = browser.divs(class: "a-box-group").count
    for idx in 0..(page_item_count - 1) do
      browser.div(class: "a-box-group", index: idx).scroll.to
      browser.div(class: "a-box-group", index: idx).elements(class: "a-popover-trigger").last.click
      browser.div(class: "a-popover").elements(class: "a-list-item").last.wait_until(&:present?).click
      browser.wait
      browser.as.first.click
      browser.wait
      browser.back
      browser.back
    end
    if browser.element(class: "a-last").a.exists?
      next_url = browser.element(class: "a-last").a.href
      browser.goto(next_url)
      browser.wait
      self.download_receipt(browser)
    end

    browser

  end


  def self.login_and_batch_scrape
    browser = self.login
    array = []
    # years = [2018, 2017]
    years = [2020]
    years.each do |year|
      self.goto_history(browser, year)
      array.concat(self.scrape_history(browser))
    end

    array
    
  end

  def self.login_and_batch_download
    browser = self.login
    # years = [2018, 2017]
    years = [2019]
    years.each do |year|
      self.goto_history(browser, year)
      self.download_receipt(browser)
    end
  end

end
