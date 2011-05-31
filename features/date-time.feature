@time
Feature: Dates and Times

 Scenario: Adding a duration
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And that [/a] is set to [f:date-time("2010-01-01 00:00:00")]
     And that [/b] is set to [f:duration(1)]
     And that [/d] is set to [f:hour-duration(12)]
     And that [/c] is set to [/a + /b]
     And that [/e] is set to [/a + /d]
   Then the expression (/c) should equal [f:date-time("2010-01-02 00:00:00")]
     And the expression (/c/@type) should equal [f:uri('f:date-time')]
     And the expression (/e) should equal [f:date-time("2010-01-01 12:00:00")]
     And the expression (/e/@type) should equal [f:uri('f:date-time')]
     And the expression (f:hours-from-duration(/d)) should equal [12]
     And the expression (f:days-from-duration(/d)) should equal [0]
     And the expression (f:month-from-date(/a)) should equal [1]
     And the expression (f:year-from-date(/a)) should equal [2010]
     And the expression (f:day-from-date(/c)) should equal [2]
