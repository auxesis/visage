Feature: Viewing data
  To find out how systems are performing
  A user
  Must be able to visualise the data

  Background:
    Given I am using a profile based on "stub"

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
    When I go to /profiles
    Then I should see a list of recently shared profiles

  @javascript @anonymous
  Scenario: Create an anonymous profile
    When I go to /profiles/new
    And I add a graph
    And I share the profile
    Then I should see a permalink for the profile

  @javascript @anonymous
  Scenario: Update an anonymous profile
    When I create an anonymous profile
    And I visit that anonymous profile
    And I add a graph
    And I share the profile
    Then I should see a new permalink for the profile

  @javascript @anonymous
  Scenario: Delete an anonymous profile
    When I create an anonymous profile
    And I visit that anonymous profile
    And I activate the share modal
    And I delete the profile
    Then I should be at /profiles

  @javascript @named
  Scenario: Create a named profile
    When I go to /profiles/new
    And I add a graph
    And I share the profile with the name "Collection of graphs"
    Then I should see a permalink for the profile
    When I go to /profiles
    Then I should see a profile named "Collection of graphs"
    When I visit a profile named "Collection of graphs"
    Then I should see "Collection of graphs" in the page title

  @javascript @named
  Scenario: Update a named profile
    When I create a profile named "Collection of graphs"
    And I visit a profile named "Collection of graphs"
    And I add a graph
    And I share the profile with the name "A different collection of graphs"
    Then I should see a permalink for the profile
    When I go to /profiles
    Then I should see a profile named "A different collection of graphs"
    Then I should not see a profile named "Collection of graphs"

  @javascript @named
  Scenario: Delete a named profile
    When I create a profile named "Graphs to delete"
    And I visit a profile named "Graphs to delete"
    And I activate the share modal
    And I delete the profile
    Then I should be at /profiles
    Then I should not see a profile named "Graphs to delete"

  @javascript @timeframe
  Scenario: Timeframe specifier
    When I go to /profiles/new
    And I set the timeframe to "last 6 hours"
    And I add a graph
    Then the graphs should have data for the last 6 hours

  @javascript @timeframe
  Scenario: Use the existing timeframe
    When I go to /profiles/new
    And I set the timeframe to "last 2 hours"
    When I go to /profiles/new
    And I add a graph
    Then the graphs should have data for the last 2 hours

  @javascript @timeframe
  Scenario: Remember a timeframe on a profile
    When I go to /profiles/new
    And I set the timeframe to "last 12 hours"
    And I add a graph
    And I remember the timeframe when sharing the profile named "Remember the timeframe"
    And I reset the timeframe
    And I visit a profile named "Remember the timeframe"
    Then the graphs should have data for the last 12 hours

  Scenario: Store relative timeframes
  Scenario: Store absolute timeframes
  Scenario: 95e on graphs
  Scenario: Store tags on profile
  Scenario: Filter profiles by tags

  @javascript @validation
  Scenario: Create a profile without any graphs
    When I go to /profiles/new
    And I share the profile
    Then I should not see a permalink for the profile
    And I should see a modal prompting me to add graphs
    And I should only see a button to close the dialog
