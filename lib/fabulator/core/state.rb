module Fabulator
  module Core
  class State
    attr_accessor :name, :transitions

    def initialize
      @transitions = []
      @pre_actions = nil
      @post_actions = nil
    end

    def compile_xml(xml, c_attrs)
      @name = xml.attributes.get_attribute_ns(FAB_NS, 'name').value
      inheriting = !@transitions.empty?
      attrs = ActionLib.collect_attributes(c_attrs, xml)
      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS
        case e.name
          when 'goes-to':
            if inheriting
              target = e.attributes.get_attribute_ns(FAB_NS, 'view').value
              tags = (e.attributes.get_attribute_ns(FAB_NS, 'tag').value rescue '').split(/\s+/)
              old = @transitions.collect{ |t| t.state == target && (tags.empty? || !(tags & t.tags).empty?)}
              if old.empty?
                @transitions << Transition.new.compile_xml(e,attrs)
              else
                old.each do |t|
                  t.compile_xml(e,attrs)
                end
              end
            else 
              @transitions << Transition.new.compile_xml(e, attrs)
            end
          when 'before':
            ActionLib.with_super(@pre_actions) do
              t = ActionLib.compile_actions(e, attrs)
              @pre_actions = t if @pre_actions.nil? || !t.is_noop?
            end
          when 'after':
            ActionLib.with_super(@post_actions) do
              t = ActionLib.compile_actions(e, attrs)
              @post_actions = t if @post_actions.nil? || !t.is_noop?
            end
        end
      end
      self
    end

    def states
      @transitions.map { |t| t.state }.uniq
    end

    def select_transition(context,params)
      # we need hypthetical variables here :-/
      best_match = nil
      @transitions.each do |t|
        res = t.validate_params(context,params)
        if res[:missing].empty? && res[:messages].empty? && res[:unknown].empty? && res[:invalid].empty?
          res[:transition] = t
          return res
        end
        if best_match.nil? || res[:score] > best_match[:score]
          best_match = res
          best_match[:transition] = t
        end
      end
      return best_match
    end

    def run_pre(context)
      # do queries, denials, assertions in the order given
      @pre_actions.run(context) unless @pre_actions.nil?
      return []
    end

    def run_post(context)
      # do queries, denials, assertions in the order given
      @post_actions.run(context) unless @post_actions.nil?
      return []
    end
  end
  end
end
