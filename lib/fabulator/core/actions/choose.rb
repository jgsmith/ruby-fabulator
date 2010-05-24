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

  class Block
    def compile_xml(xml, c_attrs = {})
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
       return @actions.run(context,autovivify)
    end
  end

  class Goto  
    def compile_xml(xml, c_attrs = {})
      @test = ActionLib.get_local_attr(xml, FAB_NS, 'test', { :eval => true })
      @state = ActionLib.get_local_attr(xml, FAB_NS, 'view')   
      self
    end

    def run(context, autovivify = false)
      raise Fabulator::StateChangeException, @state, caller if @test.nil?
      test_res = @test.run(context).collect{ |a| !!a.value }
      return [ ] if test_res.nil? || test_res.empty? || !test_res.include?(true)
      raise Fabulator::StateChangeException, @state, caller
    end
  end

  class Catch
    def compile_xml(xml, c_attrs = {})
      @test = ActionLib.get_local_attr(xml, FAB_NS, 'test', { :eval => true })
      @as = ActionLib.get_local_attr(xml, FAB_NS, 'as')
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run_test(context)
      return true if @test.nil?
      context.in_context do
        context.set_ctx_var(@as, context) if @as
        result = @test.run(context).collect{ |a| !!a.value }
        return false if result.nil? || result.empty? || !result.include?(true)
        return true
      end
    end

    def run(context, autovivify = false)
      context.in_context do
        context.set_ctx_var(@as, context) if @as
        return @actions.run(context)
      end
    end
  end

  class Raise
    def compile_xml(xml, c_attrs={})
      @test = ActionLib.get_local_attr(xml, FAB_NS, 'test', { :eval => true })
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
      if !@test.nil?
        test_res = @test.run(context).collect{ |a| !!a.value }
        return [ ] if test_res.nil? || test_res.empty? || !test_res.include?(true)
      end
      res = [ ]
      if @select.nil? && !@actions.nil?
        res = @actions.run(context, autovivify)
      elsif !@select.nil?
        res = @select.run(context, autovivify)
      else
        raise context   # default if <raise/> with no attributes
      end

      return [ ] if res.empty?

      raise Fabulator::Expr::Exception.new(res.first)
    end
  end

  class Super
    def compile_xml(xml, c_attrs={})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      @actions = ActionLib.current_super
    end

    def run(context, autovivify = false)
      return [] if @actions.nil?

      new_context = @select.run(context,autovivify)

      new_context = [ new_context ] unless new_context.is_a?(Array)

      new_context.collect { |c| @actions.run(c, autovivify) }.flatten
    end
  end

  end
  end
end
