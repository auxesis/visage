Feature: command line utility
  As a systems administrator
  Or a hard core developer
  I want to get Visage up and running
  With the least hassle possible

  Scenario: Command line tool
    Given the "visage" gem is installed
    When I start the visage server helper with "visage start"
    Then a visage web server should be running

  Scenario: Seeing where Visage is getting its data from
    Given the "visage" gem is installed
    When I start the visage server helper with "visage start"
    Then I should see "Looking for RRDs in /.*collectd" on the terminal


