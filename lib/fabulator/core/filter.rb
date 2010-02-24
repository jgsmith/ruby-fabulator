module Fabulator
  module Core
  class Filter
    def compile_xml(xml, c_attrs = { })
      filter_type = xml.attributes.get_attribute_ns(FAB_NS, 'name').value.split(/:/, 2)
      #filter_type = ActionLib.get_local_attr(xml, FAB_NS, 'name').split(/:/, 2)
      if filter_type.size == 2
        @ns = ActionLig.prefix_to_ref(xml, filter_type[0]) 
        @name = filter_type[1]
      else
        @ns = FAB_NS
        @name = filter_type[0]
      end
      self
    end

    def run(context)
      # do special ones first
      items = context.is_a?(Array) ? context : [ context ]
      filtered = [ ]
      handler = Fabulator::ActionLib.namespaces[@ns]

      items.each do |c|
        r = handler.run_filter(c, @name)
        r = [ r ] unless r.is_a?(Array)
        filtered = filtered + r.collect{ |c| c.path }
      end
      return filtered
    end
  end
  end
end
