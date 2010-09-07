#
# Allows definition of a lib as XSM stuff -- the glue between the core
# engine and the lib definition
#

# need a way to specify a library entry type -- to support grammars

# library ns: http://dh.tamu.edu/ns/fabulator/1.0#
#<f:library f:ns="">
#  <action name=''>
#    <attribute name='' type='' as='' />  (could be type='expression')
#    actions...
#  </action>
#
# <structure name=''>
#   <attribute ... />
#   <element ... />
#   actions
# </structure>
#
#  <function name=''>
#    actions...
#  </function>
#
#  <type name=''>
#    <op name=''>
#      actions...
#    </op>
#    <to name='' weight=''>
#      actions...
#    </to>
#    <from name='' weight=''>
#      actions...
#    </from>
#  </type>
#
#  <filter name=''>
#     actions...
#  </filter>
#
#  <constraint name=''>
#    actions...
#  </constraint>
#</library>

require 'fabulator/lib/lib'
require 'fabulator/lib/structural'
require 'fabulator/lib/action'
require 'fabulator/lib/attribute'

module Fabulator
  module Lib
  class LibLib < Fabulator::TagLib
    namespace FAB_LIB_NS

    structural :library, Lib
    structural :structural, Structural
    structural :action, Action
    structural :attribute, Attribute
    #structural :function, Function
    #structural :mapping, Mapping
    #structural :reduction, Reduction
    #structural :consolidation, Consolidation
    #structural :type, Type
    #structural :filter, Filter
    #structural :constraint, Constraint
  end
  end
end
