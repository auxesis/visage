Feature: Metric metadata
  To view the data
  In an identifiable way
  A user
  Needs meaningful labels

  Scenario: Retreive a list of types
    When I go to /meta/types
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a list of types

