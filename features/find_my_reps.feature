Feature: Finding my reps
  As a visitor
  I want to find who all my local elected officials are
  So that I can nag them

  Scenario: Looking at Montrose
    Given "Sylvester Turner" is mayor of "Houston"
    And "Virg Bernero" is mayor of "Lansing"
    When I go to the main page
    And I fill in "location" with "410 Sul Ross St 77006"
    And I click on "Submit"
    Then I should see "Sylvester Turner"
    And I should not see "Virg Bernero"
