@paths
Feature: Path expressions

  Scenario: Finding the numbers
    Given a context
      And that [/a] is set to [1 .. 10]
    When I run the expression (/a)
    Then I should get 10 items

  Scenario: Finding the positive numbers
    Given a context
      And that [/a] is set to [-1 .. 10]
    When I run the expression (/a[. > 0])
    Then I should get 10 items

  Scenario: Finding the odd numbers
    Given a context
      And that [/a] is set to [1 .. 10]
    When I run the expression (/a[. mod 2 = 1])
    Then I should get 5 items
      And item 0 should be [1]
      And item 1 should be [3]
      And item 2 should be [5]
      And item 3 should be [7]
      And item 4 should be [9]

  Scenario: Finding the third odd number
    Given a context
      And that [/a] is set to [1 .. 10]
    When I run the expression (/a[. mod 2 = 1][3])
    Then I should get 1 item
      And item 0 should be [5]

  Scenario: Finding the third and fifth odd numbers
    Given a context
      And that [/a] is set to [1 .. 10]
    When I run the expression (/a[. mod 2 = 1][3,5])
    Then I should get 2 items
      And item 0 should be [5]
      And item 1 should be [9]
