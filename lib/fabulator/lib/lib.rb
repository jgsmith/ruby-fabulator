module Fabulator
  module Lib
  class Lib < Fabulator::Structural

    namespace FAB_LIB_NS

    element :library
    
    attribute :ns, :static => true

    contains :action, :storage => :hash, :key => :name
    contains :structural, :storage => :hash, :key => :name
    contains :function, :storage => :hash, :key => :name
    contains :mapping, :storage => :hash, :key => :name
    contains :reduction, :storage => :hash, :key => :name
    contains :consolidation, :storage => :hash, :key => :name
    contains :type, :storage => :hash, :key => :name
    contains :filter, :storage => :hash, :key => :name
    contains :constraint, :storage => :hash, :key => :name

    def register_library
      Fabulator::TagLib.namespaces[self.ns] = self
    end

    def compile_action(e, c_attrs)
    end

    def run_function(context, nom, args)
      # look for a function/mapping/consolidation
      # then pass along to any objects in @contained

      

      return [] if @contained.nil?

      @contained.each do |c|
        ret = c.run_function(context, nom, args)
        return ret unless ret.nil? || ret.empty?
      end
      []
    end   

    def function_return_type(name)
      (self.function_descriptions[name][:returns] rescue nil)
    end

    def function_args
      @function_args ||= { }
    end

    def run_filter(context, nom)
      return if @contained.nil?
      @contained.each do |c|
        ret = c.run_filter(context, nom)
        return ret unless ret.nil?
      end
      nil
    end
 
    def run_constraint(context, nom)
      return if @contained.nil?
      @contained.each do |c|
        ret = c.run_constraint(context, nom)
        return ret unless ret.nil?
      end
      false
    end
  end
  end
end
