module Fabulator
  module Lib
    class Function < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Mapping < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Reduction < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Consolidation < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_actions
    end

    class Template < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      def compile_xml(xml, context)
        super

        @actions = [ ]
        @wrapper = [ ]

        if !xml.nil?
          ctx = nil
          if xml.name == 'template' && xml.namespaces.namespace.href == FAB_LIB_NS
            ctx = @context.merge(xml)
            @wrapper = [ '', '' ]
          else
            ctx = @context.merge
            # we need to set @wrapper to [ begin, end ]
            s = ""
            if (xml.namespaces.namespace.prefix rescue nil)
              s += xml.namespaces.namespace.prefix + ":"
            end
            s += xml.name
            e = "</" + s + ">"
            s = "<" + s
            xml.each_attr do |attr|
              s += " "
              if attr.ns?
                s += attr.ns.prefix + ":"
              end
              s += attr.name + "="
              if attr.value =~ /"/
                s += "'" + attr.value.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/'/, '&quot;') + "'"
              else
                s += '"' + attr.value.gsub(/&/, '&amp;').gsub(/</, '&lt;') + '"'
              end
            end
            s += ">"
            @wrapper = [ s, e ]
          end
          xml.each_child do |node|
            if node.element?
              if ctx.action_exists?((node.namespaces.namespace.href rescue nil), node.name)
                @actions << ctx.compile_action(node)
              else 
                a = self.class.new
                a.compile_xml(node, ctx)
                @actions << a
              end
            elsif node.text? || node.cdata?
              @actions << node.content
            end
          end
        end

        self
      end

      def run(context, autovivify = false)
        s = ''
        @context.with(context) do |ctx|
          @actions.each do |action|
            if action.is_a?(String)
              s += action
            else
              r = action.run(ctx, autovivify)
              s += r.collect { |v| v.to([FAB_NS, 'string'], ctx).value }.join('')
            end
          end
        end
        s = @wrapper.first + s + @wrapper.last
        return [ context.root.anon_node(s, [ FAB_NS, 'string' ]) ]
      end
    end
  end
end

