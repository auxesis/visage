Feature: Export data
  To perform analysis
  A user
  Must be able to extract data
  From the application

  Scenario: Retrieve single plugin instance
    When I go to /data/theodor/memory/memory-free
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a plugin instance named "memory-free"

  Scenario: Retrieve multiple plugin instances
    When I go to /data/theodor/memory
    Then the request should succeed
    Then I should receive valid JSON
    And the JSON should have a plugin named "memory"
    And the JSON should have multiple plugin instances under the "memory" plugin

  Scenario: Make cross-domain requests
    When I go to /data/theodor/cpu-0?callback=foobar
    Then I should receive JSON wrapped in a callback named "foobar"

  Scenario: Retrieve multiple plugin instances without color definition
    When I go to /data/theodor/memory
    Then the request should succeed
    Then I should receive valid JSON
    And each plugin instance should have a different color
  
  Scenario Outline: Return only one colour per metric
    When I go to /data/theodor/<path> 
    Then the request should succeed
    Then I should receive valid JSON
    And each plugin instance should have a different color

  Examples: 
    | path           |
    | cpu-0/cpu-user |
    | df/df-root     |

  Scenario: Retrieve single plugin instance with a color definition
    When I go to /data/theodor/tcpconns-80-local/tcp_connections-LISTEN
    Then the request should succeed
    Then I should receive valid JSON
    And the plugin instance should have a color

  Scenario: Retrieve a multiple plugins through a glob
    Given I have the "tcpconns" plugin collecting data on multiple ports
    When I go to /data/theodor/tcpconns-*-local/tcp_connections-LISTEN
    Then the request should succeed
    Then I should receive valid JSON
    And I should see multiple plugins

  Scenario Outline: Retrieve multple hosts through a glob
    Given I have the "memory" plugin collecting data on multiple ports
    When I go to /data/<host>/libvirt/virt_cpu_total
    Then the request should succeed
    Then I should receive valid JSON
    And I should see multiple hosts

  Examples: 
    | host                    |
    | *                       |
    | %7Brgh,flapjack-test%7D |




