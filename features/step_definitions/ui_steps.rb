When %r{I fill in "(.*)" with "(.*)"} do |field, value|
  fill_in field, with: value
end

When %r{I click on "(.*)"} do |button|
  click_on button
end

When %r{I debug} do
  require 'pry'
  binding.pry
end

Then %r{I should see "(.*)"} do |text|
  expect(page).to have_text(text)
end
