require File.dirname(__FILE__) + '/test_helper.rb'
require 'fabulator'

class TestFabulator < Test::Unit::TestCase

  def setup
  end
  
  test 'compile trivial application' do
    doc = LibXML::XML::Document.string('<f:application xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#" />')
    sm = Fabulator::Core::StateMachine.new.compile_xml(doc)
    assert_equal sm.states.keys.size, 1, "No states defined automatically"
    assert_equal sm.states.keys.first, 'start', "Default state is not 'start'"
    start = sm.states.values.first
    assert_equal start.name, "start", "Default state object doesn't know itself as 'start'"
  end
end
