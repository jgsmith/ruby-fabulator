module Fabulator
  module Core
  module Actions
  class Choose
    def compile_xml(xml, c_attrs = {})
      @choices = [ ]
      @default = nil
      attrs = ActionLib.collect_attributes(c_attrs, xml)

      xml.each_element do |e|
        next unless e.namespaces.namespace.href == FAB_NS
        case e.name
          when 'when':
            @choices << When.new.compile_xml(e, attrs)
          when 'otherwise':
            @default = When.new.compile_xml(e, attrs)
        end
      end
      self
    end

    def run(context, autovivify = false)
      @choices.each do |c|
        if c.run_test(context)
          return c.run(context)
        end
      end
      return @default.run(context) unless @default.nil?
      return []
    end
  end

  class When
    def compile_xml(xml, c_attrs = {})
      @test = ActionLib.get_local_attr(xml, FAB_NS, 'test', { :eval => true })
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run_test(context)
      return true if @test.nil?
      result = @test.run(context).collect{ |a| !!a.value }
      return false if result.nil? || result.empty? || !result.include?(true)
      return true
    end

    def run(context, autovivify = false)
      return @actions.run(context)
    end
  end

  class If
    def compile_xml(xml, c_attrs = {})
      @test = ActionLib.get_local_attr(xml, FAB_NS, 'test', { :eval => true })
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
      return [ ] if @test.nil?
      test_res = @test.run(context).collect{ |a| !!a.value }
      return [ ] if test_res.nil? || test_res.empty? || !test_res.include?(true)
      return @actions.run(context)
    end
  end
  end
  end
end
