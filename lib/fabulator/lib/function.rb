module Fabulator
  module Lib
    class Function < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_select nil
      
      def run(context, autovivify = false)
        self.select(@context.merge(context))
      end
    end

    class Mapping < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_select nil
      
      def run(context, autovivify = false)
        self.select(@context.merge(context))
      end
    end

    class Reduction < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_select nil
      
      def run(context, autovivify = false)
        self.select(@context.merge(context))
      end
    end

    class Consolidation < Fabulator::Structural
      namespace FAB_LIB_NS

      attribute :name, :static => true

      has_select nil
      
      def run(context, autovivify = false)
        self.select(@context.merge(context))
      end
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
          if xml.name == 'template' && xml.namespace.href == FAB_LIB_NS
            ctx = @context.merge(xml)
            @wrapper = [ '', '' ]
          else
            ctx = @context.merge
            # we need to set @wrapper to [ begin, end ]
            s = ""
            if (xml.namespace.prefix rescue nil)
              s += xml.namespace.prefix + ":"
            end
            s += xml.name
            e = "\n</" + s + ">"
            s = "<" + s
            xml.attribute_nodes.each do |attr|
              s += " "
              if !attr.namespace.nil?
                s += attr.namespace.prefix + ":"
              end
              s += attr.name + "="
              if attr.value =~ /"/
                s += "'" + attr.value.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/'/, '&quot;') + "'"
              else
                s += '"' + attr.value.gsub(/&/, '&amp;').gsub(/</, '&lt;') + '"'
              end
            end
            s += ">\n"
            @wrapper = [ s, e ]
          end
          xml.children.each do |node|
            if node.element?
              if ctx.action_exists?((node.namespace.href rescue nil), node.name)
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
# we want to see if we need to remove a whitespace prefix
       
        
        s = s.split(/[\x0a\x0d\n]/).collect{ |l| (l =~ /^\s*$/) ? '' : l}
        if s.first == ''
          s.shift
        end
        if s.last == ''
          s.pop
        end
        s = s.join("\n")
        indent = s.
                 split(/[\n]/m).
                 map{|l| (v=l[/^([\s]+)/].to_s.length; v==0)? nil : v }.
                 compact.min
        s.gsub!(/^#{' '*indent.to_i}/, '')
        s = @wrapper.first + s + @wrapper.last
        return [ context.root.anon_node(s, [ FAB_NS, 'string' ]) ]
      end
    end
  end
end

