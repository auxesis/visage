Feature: Visit site
  To find out how systems are performing
  A user
  Must be able to visualise the data

  Scenario: Visit site
    When I go to /
    Then I should see "sinatra-collectd"
    Then show me the page
