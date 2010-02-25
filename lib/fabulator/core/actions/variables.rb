module Fabulator
  module Core
  module Actions
  class ValueOf
    def compile_xml(xml, c_attrs = {})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      self
    end

    def run(context, autovivify = false)
      @select.run(context)
    end
  end

  class Value
    attr_accessor :select, :name

    def compile_xml(xml, c_attrs = {})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true, :default => nil })
      @name = ActionLib.get_local_attr(xml, FAB_NS, 'path', { :eval => true })
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
      return context.set_value(@name, @select.nil? ? @actions : @select )

      return [] if @name.nil?
      tgt = @name.run(context, true).first
      src = nil
      if @select.nil?
        @actions.each do |action|
          src = action.run(context)
        end
      else
        src = @select.run(context)
      end
      tgt.prune
      ret = [ ]
      if src.nil? || src.empty?
        tgt.value = nil
        ret << tgt
      elsif src.size == 1
        tgt.copy(src.first)
        ret << tgt
      else
        p = tgt.parent
        nom = tgt.name
        p.prune(p.children(nom))
        src.each do |s|
          tgt = p.create_child(nom,nil)
          tgt.copy(s)
          ret << tgt
        end
      end
      ret
    end
  end

  class Variable
    def compile_xml(xml, c_attrs = {})
      @select = ActionLib.get_local_attr(xml, FAB_NS, 'select', { :eval => true })
      @name = (xml.attributes.get_attribute_ns(FAB_NS, 'name').value rescue nil)
      @actions = ActionLib.compile_actions(xml, c_attrs)
      self
    end

    def run(context, autovivify = false)
      return [] if @name.nil?
      res = [ ]
      if @select
        res = @select.run(context)
      elsif !@actions.empty?
        @actions.each do |a|
          res = a.run(context)
        end
      end
      context.set_var(@name, res)
      res
    end
  end
  end
  end
end
