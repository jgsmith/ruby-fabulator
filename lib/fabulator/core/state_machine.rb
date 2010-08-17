require 'yaml'
require 'xml/libxml'

module Fabulator
  FAB_NS='http://dh.tamu.edu/ns/fabulator/1.0#'
  RDFS_NS = 'http://www.w3.org/2000/01/rdf-schema#'
  RDF_NS = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  RDFA_NS = 'http://dh.tamu.edu/ns/fabulator/rdf/1.0#'

  class StateChangeException < Exception
  end

  module Core

  class StateMachine
    attr_accessor :states, :missing_params, :errors, :namespaces, :updated_at
    attr_accessor :state

    def initialize
      @states = { }
      @context = Fabulator::Expr::Context.new
      @state = 'start'
    end

    def compile_xml(xml, context = nil, callbacks = { })
      # /statemachine/states
      if xml.is_a?(String)
        XML.default_line_numbers = true
        xml = LibXML::XML::Document.string xml
      end

      if context.nil?
        @context = @context.merge(xml.root)
      else
        @context = context.merge(xml.root)
      end

      ActionLib.with_super(@actions) do
        p_actions = @context.compile_actions(xml.root)
        @actions = p_actions if @actions.nil? || !p_actions.is_noop?
      end

      xml.root.each_element do |child|
        next unless child.namespaces.namespace.href == FAB_NS
        case child.name
          when 'view':
            nom = (child.attributes.get_attribute_ns(FAB_NS, 'name').value rescue nil)
            if !@states[nom].nil?
              @states[nom].compile_xml(child, @context)
            else
              @states[nom] = State.new.compile_xml(child, @context)
            end
        end
      end

      if @states.empty?
        s = State.new
        s.name = 'start'
        @states['start'] = s
      end
      self
    end

    def clone
      YAML::load( YAML::dump( self ) )
    end

    def namespaces 
      @context.ns
    end

    def init_context(c)
      @context.root = c.root
      begin
        @actions.run(@context)
      rescue Fabulator::StateChangeException => e
        @state = e
      end
    end

    def context
      { :data => @context.root, :state => @state }
    end

    def fabulator_context
      @context
    end

    def context=(c)
      if c.is_a?(Fabulator::Expr::Context)
        @context = c
      elsif c.is_a?(Fabulator::Expr::Node)
        @context.root = c
      elsif c.is_a?(Hash)
        @context.root = c[:data]
        @state = c[:state]
      end
    end

    def run(params)
      current_state = @states[@state]
      return if current_state.nil?
      # select transition
      # possible get some errors
      # run transition, and move to new state as needed
      @context.in_context do |ctx|
        self.run_transition(current_state.select_transition(@context, params))
      end
    end

    def run_transition(best_transition)
      return if best_transition.nil? || best_transition.empty?
      current_state = @states[@state]
      t = best_transition[:transition]
      @missing_params = best_transition[:missing]
      @errors = best_transition[:messages]
      if @missing_params.empty? && @errors.empty?
        @state = t.state
        # merge valid and context
        best_transition[:valid].sort_by { |a| a.path.length }.each do |item|
          p = item.path.gsub(/^[^:]+::/, '').split('/') - [ '' ]
          n = @context.traverse_path(p, true).first
          n.prune
          n.copy(item)
        end
        # run_post of state we're leaving
        begin
          current_state.run_post(@context)
          t.run(@context)
          # run_pre for the state we're going to
          new_state = @states[@state]
          new_state.run_pre(@context) if !new_state.nil?
        rescue Fabulator::StateChangeException => e # catch state change
          new_state = @states[e]
          begin
            if !new_state.nil?
              @state = new_state.name
              new_state.run_pre(@context)
            end
          rescue Fabulator::StateChangeException => e
            new_state = @states[e] 
            retry
          end
        end
      end
    end

    def data
      @context.root
    end

    def state_names
      (@states.keys.map{ |k| @states[k].states }.flatten + @states.keys).uniq
    end
  end
  end
end
