Feature: Expression primitives

 @tuple
 Scenario: Simple 1-tuple
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And that [/a] is set to [[1,1]]
   Then the expression (/a/@size) should equal [2]
     And the expression (f:string(/a/@type)) should equal [f:uri-prefix('f') + "tuple"]

 @bag
 Scenario: Simple bag
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And that [/a] is set to [({ foo: 3, bar: "foo", foo/baz: "bar" })]
   Then the expression (/a/foo) should equal [3]
     And the expression (/a/bar) should equal ["foo"]
     And the expression (/a/foo/baz) should equal ["bar"]
