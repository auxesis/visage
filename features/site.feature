Feature: Visit site
  To find out how systems are performing
  A user
  Must be able to visualise the data

  Scenario: Show available hosts
    When I go to /profiles
    And I visit the first profile
    Then I should see a list of graphs


