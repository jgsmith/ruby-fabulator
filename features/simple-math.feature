Feature: Simple Math

  Scenario: Adding two numbers together
   Given a context
     And that /a is set to 2
     And that /b is set to 1
   When I run the expression (a + b) in the context /
   Then I should get 1 item
     And item 0 should be [3]

  Scenario: Subtracting two numbers
   Given a context
     And that /a is set to 2
     And that /b is set to 1
   When I run the expression (a - b) in the context /
   Then I should get 1 item
     And item 0 should be [1]

  Scenario: Multiplying two numbers
   Given a context
     And that /a is set to 3
     And that /b is set to 7
   When I run the expression (a * b) in the context /
   Then I should get 1 item
     And item 0 should be [21]

  Scenario: Dividing two numbers
   Given a context
     And that /a is set to 30
     And that /b is set to 6
   When I run the expression (a div b) in the context /
   Then I should get 1 item
     And item 0 should be [5]

   
