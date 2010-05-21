@sm
Feature: Simple state machines

  Scenario: simple machine with just one state and no transitions
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#" />
      """
    Then it should be in the 'start' state

  Scenario: simple machine with a simple transition
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:view f:name="start">
            <f:goes-to f:view="stop">
              <f:params>
                <f:param f:name="foo"/>
              </f:params>
            </f:goes-to>
          </f:view>
          <f:view f:name="stop" />
        </f:application>
      """
    Then it should be in the 'start' state
    When I run it with the following params:
      | key   | value |
      | foo   | bar   |
    Then it should be in the 'stop' state
     And the expression (/foo) should equal ['bar']
    When I run it with the following params:
      | key   | value |
      | foo   | bar   |
    Then it should be in the 'stop' state
     And the expression (/foo) should equal ['bar']

  Scenario: simple machine with a simple transition and filter
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:view f:name="start">
            <f:goes-to f:view="stop">
              <f:params>
                <f:param f:name="foo">
                  <f:filter f:name="trim" />
                </f:param>
              </f:params>
            </f:goes-to>
          </f:view>
          <f:view f:name="stop" />
        </f:application>
      """
    Then it should be in the 'start' state
    When I run it with the following params:
      | key   | value         |
      | foo   | bar  b  que   |
    Then it should be in the 'stop' state
     And the expression (/foo) should equal ['bar b que']

  Scenario: simple machine with a simple transition and simple value constraint
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:view f:name="start">
            <f:goes-to f:view="stop">
              <f:params>
                <f:param f:name="foo">
                  <f:filter f:name="trim" />
                  <f:value>bar</f:value>
                </f:param>
              </f:params>
            </f:goes-to>
          </f:view>
          <f:view f:name="stop" />
        </f:application>
      """
    Then it should be in the 'start' state
    When I run it with the following params:
      | key   | value         |
      | foo   | bar  b  que   |
    Then it should be in the 'start' state
     And the expression (/foo) should be nil
    When I run it with the following params:
      | key   | value |
      | foo   | bar   |
    Then it should be in the 'stop' state
     And the expression (/foo) should equal ['bar']

  Scenario: simple machine with a <ensure />
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:value f:path="/foo" f:select="'bar'" />
          <f:ensure>
            <f:value f:path="/foo" f:select="'baz'" />
          </f:ensure>
        </f:application>
      """
    Then it should be in the 'start' state
     And the expression (/foo) should equal ['baz']

  Scenario: simple machine with a <catch />
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:value f:path="/foo" f:select="'bar'" />
          <f:ensure>
            <f:value f:path="/foo" f:select="'baz'" />
          </f:ensure>
          <f:raise f:select="'yay'" />
          <f:catch>
            <f:value f:path="/foo" f:select="'boo'" />
          </f:catch>
        </f:application>
      """
    Then it should be in the 'start' state
     And the expression (/foo) should equal ['baz']

  Scenario: simple machine with a <div />
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:value f:path="/foo" f:select="'bar'" />
          <f:div>
            <f:value f:path="/foo" f:select="'baz'" />
          </f:div>
        </f:application>
      """
    Then it should be in the 'start' state
     And the expression (/foo) should equal ['baz']

  Scenario: simple machine with a <div /> and <ensure />
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:value f:path="/foo" f:select="'bar'" />
          <f:div>
            <f:value f:path="/foo" f:select="'baz'" />
          </f:div>
          <f:ensure>
            <f:value f:path="/foo" f:select="'boo'" />
          </f:ensure>
        </f:application>
      """
    Then it should be in the 'start' state
     And the expression (/foo) should equal ['boo']

