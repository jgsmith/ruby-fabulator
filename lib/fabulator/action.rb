module Fabulator
  class Action

    def compile_xml(xml, context)
      @context = context.merge(xml)
      klass = self.class.name
      if @@attributes[klass]
        @@attributes[klass].each_pair do |nom, opts|
          as = "@" + (opts[:as] || nom).to_s
          self.instance_variable_set(as.to_sym, @context.attribute(opts[:namespace] || @@namespace[klass], nom.to_s, opts))
        end
      end
      @select = @context.get_select(@@has_select[klass]) if @@has_select[klass]
      if @@has_actions[klass]
        case @@has_actions[klass]
          when :simple:
            @actions = @context.compile_actions(xml)
          when :super:
            @actions = ActionLib.current_super
        end
      end
      self
    end

    def self.namespace(href)
      @@namespace ||= { }
      @@namespace[self.name] = href
    end

    def self.attribute(nom, opts = { })
      @@attributes ||= { }
      @@attributes[self.name] ||= { }
      @@attributes[self.name][nom.to_s] = opts
    end

    def self.has_actions(t = :simple)
      @@has_actions ||= { }
      @@has_actions[self.name] = t
    end

    def self.has_select(default = '.')
      @@has_select ||= { }
      @@has_select[self.name] = default
    end
  end
end
