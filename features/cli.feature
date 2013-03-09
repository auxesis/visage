Feature: command line utility
  As a systems administrator
  Or a hard core developer
  I want to get Visage up and running
  With the least hassle possible

  Background:
    Given the visage server helper is not running

  @daemon
  Scenario: Booting the command line tool
    Given I am using a profile based on "default"
    When I start the visage server helper with "visage-app start"
    Then a visage web server should be running

  @daemon
  Scenario: Seeing where Visage is getting its data from
    Given I am using a profile based on "default"
    When I start the visage server helper with "visage-app start"
    Then I should see "Looking for RRDs in /.*collectd" on the terminal

  @daemon
  Scenario: Booting with no config file
    Given a profile file doesn't exist
    When I start the visage server helper with "visage-app start"
    Then I should see a profile file has been created

  @daemon
  Scenario: Upgrading config from 2.0 to 3.0
    Given I am using a profile based on "2.0_profile_yaml"
    When I start the visage server helper with "visage-app start"
    Then I should see "The Visage profile format has changed" on the terminal
    And I should see "Upgrading profile format from 2.0.0 to 3.0.0" on the terminal
    And I should see "Success!" on the terminal

  @help
  Scenario Outline: Displaying the man page
    Given I am using a profile based on "default"
    When I start the visage server helper with "visage-app <argument>"
    Then I should see a man page
    And a visage web server should not be running

  Examples:
    | argument      |
    | help          |
    | --help        |
    | start help    |
    | help start    |
    | --help start  |
    | start --help  |
