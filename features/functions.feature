Feature: Function calls and lists

  Scenario: Adding two numbers together as a union
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
   When I run the expression (f:sum((1 | 2)))
   Then I should get 1 item
     And item 0 should be [3]

  Scenario: Adding two numbers together as a list
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
   When I run the expression (f:sum((1, 2)))
   Then I should get 1 item
     And item 0 should be [3]

  Scenario: Adding number of elements in a histogram, part 1
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $i := (1 .. 6) + (1 .. 6); f:sum($i))
    Then I should get 1 item
     And item 0 should be [6*6*7]

  Scenario: Adding number of elements in a histogram, part 2
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $i := (1 .. 6) + (1 .. 6); f:sum(f:histogram($i)))
    Then I should get 1 item
     And item 0 should be [6*6]

