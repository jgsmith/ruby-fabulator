Feature: Addition

  Scenario: Adding two numbers together
   Given a context
     And the path /a is set to 1
     And the path /b is set to 2
     And the expression (./a + ./b)
   When I run it in the context /
   Then I should get 1 item
