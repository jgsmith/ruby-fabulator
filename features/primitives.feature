Feature: Expression primitives

 @tuple
 Scenario: Simple 1-tuple
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
   When I run the expression (let $a := ([1,1]))
   Then the expression ($a/@size) should equal [2]
     And the expression (f:string($a/@type)) should equal [f:uri-prefix('f') + "tuple"]
