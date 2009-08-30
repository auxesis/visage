
Then /^the "(.+)" select should have "(.+)" selected$/ do |input, value|
  response_body.to_s.should have_xpath("//select[@name='#{input}']//option[contains(.,'#{value}')][@selected]")
end


