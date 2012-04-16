Feature: Export data
  To perform analysis
  A user
  Must be able to extract data
  From the application

  Scenario: Retreive a list of hosts
    When I go to /data
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a list of hosts

  Scenario: Get a list of available metrics on a host
    When I visit the first available host
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a list of plugins

  Scenario: Get a list of available metrics across many hosts
    When I visit the first two available hosts
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a list of plugins

  Scenario: Retrieve single plugin instance
    Given a list of hosts exist
    When I visit "memory/memory-free" on the first available host
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a plugin instance named "memory-free"

  Scenario: Retrieve multiple plugin instances
    Given a list of hosts exist
    When I visit "memory" on the first available host
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a plugin named "memory"
    And the JSON should have multiple plugin instances under the "memory" plugin

  Scenario: Make cross-domain requests
    Given a list of hosts exist
    When I visit "cpu-0?callback=foobar" on the first available host
    Then I should receive JSON wrapped in a callback named "foobar"

  Scenario: Retrieve multiple plugins through a glob
    Given a list of hosts exist
    When I visit "disk*/disk_ops" on the first available host
    Then the request should succeed
    Then I should receive valid JSON
    And I should see multiple plugins

  Scenario: Retrieve multple hosts through a glob
    When I go to /data/*/memory
    Then the request should succeed
    Then I should receive valid JSON
    And I should see multiple hosts

  Scenario: Retrieve data with a defined start time
    Given a list of hosts exist
    When I visit "disk*/disk_ops" on the first available host with the following query parameters:
      | parameter | value      |
      | start     | 1321769692 |
      | finish    | 1321773292 |
    Then the request should succeed
    Then I should receive valid JSON
    And I should see the following parameters for each plugin instance:
      | parameter | value      |
      | start     | 1321769692 |
      | finish    | 1321773292 |

  Scenario: Retrieve data with a defined finish time
    Given a list of hosts exist
    When I visit "disk*/disk_ops" on the first available host with the following query parameters:
      | parameter | value      |
      | finish    | 1321773292 |
    Then the request should succeed
    Then I should receive valid JSON
    And I should see the following parameters for each plugin instance:
      | parameter | value      |
      | start     | 1321769692 |
      | finish    | 1321773292 |

  Scenario: Retrieve data for a defined period including 95th percentile calculations
    Given a list of hosts exist
    When I visit "disk*/disk_ops" on the first available host with the following query parameters:
      | parameter   | value      |
      | start       | 1 hour ago |
      | finish      | now        |
      | percentiles | 95         |
    Then the request should succeed
    Then I should receive valid JSON
    And I should see a 95th percentile value for each plugin instance
