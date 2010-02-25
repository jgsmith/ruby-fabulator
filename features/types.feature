@dev
Feature: Type unification

  Scenario: A single type
    Given the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I unify the type f:integer
    Then I should get the type f:integer

  Scenario: A single type multiple times
    Given the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I unify the type f:integer, f:integer, f:integer
    Then I should get the type f:integer

  Scenario: Two types sharing a possible target type
    Given the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I unify the type f:integer, f:integer, f:real
    Then I should get the type f:real

  Scenario: Three types sharing a possible target type
    Given the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
    When I unify the type f:integer, f:integer, f:real, f:string
    Then I should get the type f:string
