module Fabulator
  module Lib
  class Lib < Fabulator::Structural

    namespace FAB_LIB_NS
    
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
      Fabulator::TagLib.namespaces[@ns] = self
      @attributes.each do |attr|
        Fabulator::TagLib.attributes << [ @ns, attr[:name], attr[:options] ]
      end
    end

    def compile_action(e, c_attrs)
    end

    def run_function(context, nom, args)
    end   

    def function_return_type(name)
      (self.function_descriptions[name][:returns] rescue nil)
    end

    def function_args
      @function_args ||= { }
    end

    def run_filter(context, nom)
    end
 
    def run_constraint(context, nom)
    end
  end
  end
end
