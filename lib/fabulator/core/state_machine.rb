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

    def compile_xml(xml, c_attrs = { })
      # /statemachine/states
      @states = { }
      self.namespaces = { }
      @state = 'start'

      attr = ActionLib.collect_attributes(c_attrs, xml.root)

      @actions = ActionLib.compile_actions(xml.root, {})
      xml.root.each_element do |child|
        next unless child.namespaces.namespace.href == FAB_NS
        case child.name
          when 'view':
            cs = State.new.compile_xml(child, attr)
            @states[cs.name] = cs
        end
      end

      xml.root.namespaces.each do |ns|
        self.namespaces[ns.prefix] = ns.href
      end
      begin
        self.namespaces[''] = xml.root.namespaces.default.href
      rescue
      end

      if @states.empty?
        s = State.new
        s.name = 'start'
        @states['start'] = s
      end
      self
    end

    def namespaces 
      @namespaces
    end

    def init_context(c)
      @context = c
      begin
        @actions.run(c)
      rescue Fabulator::StateChangeException => e
        @state = e
      end
    end

    def context
      { :data => @context, :state => @state }
    end

    def context=(c)
      if c.is_a?(Fabulator::Expr::Context)
        @context = c
      elsif c.is_a?(Hash)
        @context = c[:data]
        @state = c[:state]
      end
    end

    def run(params)
      current_state = @states[@state]
      return if current_state.nil?
      # select transition
      # possible get some errors
      # run transition, and move to new state as needed
      self.run_transition(current_state.select_transition(@context, params))
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
        best_transition[:valid].each do |item|
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
          jumps = 0
          while !new_state.nil? && new_state.transitions.size == 1 && new_state.transitions.first.param_names.size == 0 && jumps < 1000
            jumps = jumps + 1
            new_state.transitions.first.run(@context)
            new_state = @states[new_state.transitions.first.state]
          end
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
      @context
    end

    def state_names
      (@states.keys.map{ |k| @states[k].states }.flatten + @states.keys).uniq
    end
  end
  end
end
