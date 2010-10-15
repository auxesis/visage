Feature: Visit site
  To find out how systems are performing
  A user
  Must be able to visualise the data

  Scenario: List profiles
    When I go to /profiles
    Then I should see a list of profiles
    When I follow "created"
    Then I should see a list of profiles
    When I follow "name"
    Then I should see a list of profiles sorted alphabetically

  Scenario: Show profile
    When I go to /profiles
    And I visit the first profile
    Then I should see a list of graphs
    And I should see a profile heading

