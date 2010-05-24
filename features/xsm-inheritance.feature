@isa
Feature: IS-A State machine inheritance

  Scenario: simple machine with just one state and no transitions
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#" />
      """
      And the statemachine
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

  Scenario: simple machine with just one state and no transitions
    Given the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#">
          <f:value f:path="/foo" f:select="'bar'" />
        </f:application>
      """
      And the statemachine
      """
        <f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#"/>
      """
    Then it should be in the 'start' state
     And the expression (/foo) should equal ['bar']
