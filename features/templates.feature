@tmpl
Feature: Templates

  Scenario: Rendering a simple template
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And the template
       """
<foo></foo>
       """
   When I render the template
   Then the rendered text should equal
       """
<foo/>
       """

  Scenario: Rendering a choice in a template
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And the template
       """
<foo>
  <r:choose>
    <r:when test="f:true()">
      true
    </r:when>
    <r:otherwise>
      false
    </r:otherwise>
  </r:choose>
</foo>
       """
   When I render the template
   Then the rendered text should equal
       """
<foo>


      true



</foo>
       """

  Scenario: Rendering a choice in a template
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And the template
       """
<foo>
  <r:choose>
    <r:when test="f:false()">
      true
    </r:when>
    <r:otherwise>
      false
    </r:otherwise>
  </r:choose>
</foo>
       """
   When I render the template
   Then the rendered text should equal
       """
<foo>



      false


</foo>
       """

  Scenario: Rendering a form with captions
   Given a context
     And the prefix f as "http://dh.tamu.edu/ns/fabulator/1.0#"
     And the template
       """
<view>
  <form>
    <textline id='foo'><caption>Foo</caption></textline>
    <submit id='submit'/>
  </form>
</view>
       """
   When I render the template
    And I set the captions to:
      | path   | caption       |
      | foo    | FooCaption    |
      | submit | SubmitCaption |
   Then the rendered text should equal
       """
<view>
  <form>
    <textline id="foo"><caption>FooCaption</caption></textline>
    <submit id="submit"><caption>SubmitCaption</caption></submit>
  </form>
</view>
       """
