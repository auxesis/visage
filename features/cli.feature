Feature: command line utility
  As a systems administrator
  Or a hard core developer
  I want to get Visage up and running
  With the least hassle possible

  Scenario: Command line tool
    Given the "visage" gem is installed
    When I start the visage server helper with "visage-app start"
    Then a visage web server should be running

  Scenario: Seeing where Visage is getting its data from
    Given the "visage" gem is installed
    When I start the visage server helper with "visage-app start"
    Then I should see "Looking for RRDs in /.*collectd" on the terminal

  Scenario: Specified configuration directory
    Given the "visage" gem is installed
    And there is no file at "features/support/config/with_no_profiles/profiles.yaml"
    When I start the visage server helper with "visage-app start" and the following variables:
      | CONFIG_PATH                           |
      | features/support/config/with_no_profiles |
    Then I should see a file at "features/support/config/with_no_profiles/profiles.yaml"

  Scenario: Config upgrader
    Given the "visage" gem is installed
    When I start the visage server helper with "visage-app start" and the following variables:
      | CONFIG_PATH                           |
      | features/support/config/with_old_profile_yaml |
    Then I should see "The Visage profile format has changed" on the terminal
    And I should see "visage-app upgrade" on the terminal
