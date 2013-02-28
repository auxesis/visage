Feature: command line utility
  As a systems administrator
  Or a hard core developer
  I want to get Visage up and running
  With the least hassle possible

  @daemon
  Scenario: Command line tool
    When I start the visage server helper with "visage-app start"
    Then a visage web server should be running

  @daemon
  Scenario: Seeing where Visage is getting its data from
    When I start the visage server helper with "visage-app start"
    Then I should see "Looking for RRDs in /.*collectd" on the terminal

  @daemon
  Scenario: Specified configuration directory
    Given there is no file at "features/support/config/with_no_profiles/profiles.yaml"
    When I start the visage server helper with "visage-app start" and the following variables:
      | CONFIG_PATH                           |
      | features/support/config/with_no_profiles |
    Then I should see a file at "features/support/config/with_no_profiles/profiles.yaml"

  @daemon
  Scenario: Config upgrader
    When I start the visage server helper with "visage-app start" and the following variables:
      | CONFIG_PATH                                   |
      | features/support/config/with_2.0_profile_yaml |
    Then I should see "The Visage profile format has changed" on the terminal
    And I should see "Upgrading profile format from 2.0.0 to 3.0.0...success!" on the terminal
