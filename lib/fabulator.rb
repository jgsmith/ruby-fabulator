require 'active_support/inflector'

module Fabulator
  FAB_NS='http://dh.tamu.edu/ns/fabulator/1.0#'
  RDFS_NS = 'http://www.w3.org/2000/01/rdf-schema#'
  RDF_NS = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  RDFA_NS = 'http://dh.tamu.edu/ns/fabulator/rdf/1.0#'

  require 'fabulator/expr'
  require 'fabulator/tag_lib'
  require 'fabulator/action'
  require 'fabulator/structural'
  require 'fabulator/core'
  require 'fabulator/version'
end
