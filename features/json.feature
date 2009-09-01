Feature: Export data
  To perform analysis
  A user
  Must be able to extract data
  From the application

  Scenario: Show available hosts
    When I go to /data/theodor/memory
    Then I should receive valid JSON
