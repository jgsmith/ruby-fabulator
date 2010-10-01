require 'active_support/inflector'

module Fabulator
  FAB_NS='http://dh.tamu.edu/ns/fabulator/1.0#'
  FAB_LIB_NS='http://dh.tamu.edu/ns/fabulator/library/1.0#'

  require 'fabulator/expr'
  require 'fabulator/tag_lib/transformations'
  require 'fabulator/tag_lib/presentations'
  require 'fabulator/tag_lib'
  require 'fabulator/action'
  require 'fabulator/structural'
  require 'fabulator/core'
  require 'fabulator/version'
end
