Feature: Visit site
  To find out how systems are performing
  A user
  Must be able to visualise the data

  Scenario: List named profiles
    When I go to /profiles
    Then I should see a list of profiles sorted alphabetically

  Scenario: List recently shared profiles
    When I go to /profiles
    Then I should see a list of recently shared profiles

  @javascript
  Scenario: Show recent profile
    When I go to /profiles
    And I visit the first recent profile
    Then I should see a collection of graphs
    And I should see "Back to profiles"

  @javascript
  Scenario: Navigate profiles
    When I go to /profiles
    And I visit the first recent profile
    Then I should see a collection of graphs
    When I follow "Back to profiles"
    #Then show me the page
    Then I should see a list of recently shared profiles
