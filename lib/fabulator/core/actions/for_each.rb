module Fabulator
  module Core
  module Actions
  class ForEach
    def compile_xml(xml, c_attrs = {})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      @sort = [ ]

      @as = (xml.attributes.get_attribute_ns(FAB_NS, 'as').value rescue nil)

      @actions = ActionLib.compile_actions(xml, c_attrs)

      attrs = ActionLib.collect_attributes(c_attrs, xml)

      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS
        case e.name
          when 'sort-by':
            @sort << Sort.new.compile_xml(e, attrs)
        end
      end
      self
    end

    def run(context, autovivify = false)
      items = @select.run(context)
      res = nil
      context.in_context do
        if !@sort.empty?
          items = items.sort_by{ |i| 
            context.set_var(@as, i) unless @as.nil? 
            @sort.collect{|s| s.run(i) }.join("\0") 
          }
        end
        res = [ ]
        items.each do |i|
          context.set_var(@as, i) unless @as.nil?
          res = res + @actions.run(i)
        end
      end
      return res
    end
  end

  class Sort
    def compile_xml(xml, c_attrs = {})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      self
    end

    def run(context, autovivify = false)
      (@select.run(context).first.value.to_s rescue '')
    end
  end

  class Considering
    def compile_xml(xml, c_attrs = {})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      @as = (xml.attributes.get_attribute_ns(FAB_NS, 'as').value rescue nil)
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
      return [] if @select.nil?
      c = @select.run(context)
      res = [ ]
      root = nil
      if @as.nil?
        if c.size == 1
          root = c.first
        else
          root = Fabulator::Expr::Node.new('data', context.roots, nil, c)
        end
        res = @actions.run(root)
      else
        root = context
        root.in_context do
          root.set_var(@as, c)
          res = @actions.run(root)
        end
      end
      res
    end
  end

  class While
    def compile_xml(xml, c_attrs = {})
      @test = ActionLib.get_local_attr(xml, FAB_NS, 'test', { :eval => true })
      @limit = ActionLib.get_local_attr(xml, FAB_NS, 'limit', { :default => 1000 })
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
      res = [ ]
      counter = 0
      lim = @limit.nil? ? 1000 : @limit.run(context).first.value
      while counter < @limit && (!!@test.run(context).first.value rescue false)
        res = res + @actions.run(context)
      end
      res
    end
  end
  end
  end
end
