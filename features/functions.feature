@func
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
    When I run the expression (let $i := (1 .. 6) + (1 .. 6); f:sum(f:histogram($i)/*))
    Then I should get 1 item
     And item 0 should be [6*6]

  Scenario: Split a string
    Given a context
      And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $t := "The quick brown fox jumped over the brown spotted cow"; f:split($t, " "))
    Then I should get 10 items
     And item 0 should be ['The']
     And item 1 should be ['quick']

  Scenario: Histogram of text
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $t := "The quick brown fox jumped over the brown spotted cow"; f:histogram(f:split($t, " "))/brown)
    Then I should get 1 item
     And item 0 should be [2]

  Scenario: Histogram of text
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $t := f:lower-case("The quick brown fox jumped over the brown spotted cow"); f:consolidate( (f:histogram(f:split($t, " ")), f:histogram(f:split($t, " "))) )/brown)
    Then I should get 1 item
     And item 0 should be [4]

  @hist
  Scenario: Histogram of text with attributes
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $t := f:lower-case("The quick brown fox jumped over the brown spotted cow"); f:consolidate( ( (f:histogram(f:split($t, " ")) with ./*/@line := 1), (f:histogram(f:split($t, " ")) with ./*/@line := 2)) )/brown)
    Then I should get 1 item
     And item 0 should be [4]

  Scenario: Joining a range of numbers
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $i := 5; (1 .. $i))
    Then I should get 5 item
     And item 0 should be [1]
     And item 1 should be [2]
     And item 2 should be [3]
     And item 3 should be [4]
     And item 4 should be [5]

  Scenario: Joining a range of numbers
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $i := 5; f:sum((1 .. $i)))
    Then I should get 1 item
     And item 0 should be [15]

  Scenario: Joining a range of numbers
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:string-join( (1 .. 5), ','))
    Then I should get 1 item
     And item 0 should be ["1,2,3,4,5"]

  Scenario: Joining a range of numbers
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (let $i := 5; f:string-join( (1 .. $i), ','))
    Then I should get 1 item
     And item 0 should be ["1,2,3,4,5"]

  Scenario Outline: simple functions
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:<fctn>(<a>))
    Then I should get 1 item
      And item 0 should be [<ans>]

    Examples:
      | fctn     |   a  | ans |
      | abs      |   -1 |   1 |
      | abs      |    1 |   1 |
      | abs      |    0 |   0 |
      | floor    | 1.23 |   1 |
      | ceiling  | 1.23 |   2 |
      | sum      | (1,2) |  3 |
      | avg      | (1,2,3) | 2 |
      | max      | (2,3,1) | 3 |
      | min      | (3,1,2) | 1 |

  Scenario: boolean constant functions - true
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:true())
    Then I should get 1 item
      And item 0 should be true

  Scenario: boolean constant functions - false
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:false())
    Then I should get 1 item
      And item 0 should be false

  Scenario: Replacing unwanted characters in a string
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:keep("foo bar baz! ter", ('alpha', 'space', 'numeric')))
    Then I should get 1 item
      And item 0 should be ['foo bar baz  ter']

  Scenario: Replacing unwanted characters in a string
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:keep("foo bar baz! ter", ('alpha', 'numeric')))
    Then I should get 1 item
      And item 0 should be ['foo bar baz ter']

  @bool
  Scenario: Negating logic
    Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I run the expression (f:not(f:true()))
    Then I should get 1 item
      And item 0 should be [f:false()]
