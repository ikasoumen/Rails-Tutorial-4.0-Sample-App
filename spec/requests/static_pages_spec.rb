require 'spec_helper'

describe "StaticPages" do

  describe "GET /static_pages" do

    it "shoud have the content 'Sample App'" do
	visit '/static_pages/home'
	expect(page).to have_content('Sample App')

    end
  end
end
