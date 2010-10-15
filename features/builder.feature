Feature: Build profiles
  To find out how particular systems are performing
  A user
  Must be able to select a host
  And some metrics
  And see a page of graphs

  Scenario: Build a simple profile
    When I go to /builder
    And I fill in "hosts" with "*"
    And I fill in "metrics" with "*"
    And I press "metrics"
    And I fill in "profile_name" with "all on all"
    And I press "create"
    Then I should see a list of graphs
    And I should see a profile heading
