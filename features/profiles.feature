Feature: Visit site
  To find out how systems are performing
  A user
  Must be able to visualise the data

  Scenario: List profiles
    When I go to /profiles
    Then I should see a list of profiles sorted alphabetically

  Scenario: Show profile
    When I go to /profiles
    And I visit the first profile
    Then I should see a profile heading
    And I should see "Back to profiles"

  Scenario: Navigate profiles
    When I go to /profiles
    And I visit the first profile
    Then I should see a profile heading
    When I follow "back to profiles"
    Then I should see a list of profiles sorted alphabetically

