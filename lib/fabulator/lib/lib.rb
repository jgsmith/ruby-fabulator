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

    def compile_action(e, context)
      name = e.name
      return nil unless @actions.has_key?(name)
      @actions[name].compile_action(e, context)
    end

    def get_action(nom, context)
      return nil unless @actions.has_key?(nom)
      @actions[nom]
    end

    def run_function(context, nom, args)
      # look for a function/mapping/consolidation
      # then pass along to any objects in @contained

      fctn = nil
      fctn_type = nil

      if nom =~ /^(.*)\*$/
        cnom = $1
        if !@consolidations[cnom].nil?
          fctn = @consolidations[cnom]
          fctn_type = :reduction
        end
      else
        if @consolidations.has_key?(nom)
          fctn = @reductions[nom]
          fctn_type = :reduction
        end
        if fctn.nil?
          fctn = @mappings[nom]
          fctn_type = :mapping
        end
        if fctn.nil?
          fctn = @functions[nom]
          fctn_type = :function
        end
        if fctn.nil?
          fctn = @reductions[nom]
          fctn_type = :reduction
        end
      end

      if !fctn.nil?
        res = [ ]
        context.in_context do |ctx|
          args = args.flatten
          case fctn_type
            when :function:
              args.size.times do |i|
                ctx.set_var((i+1).to_s, args[i])
              end
              ctx.set_var('0', args)
              res = fctn.run(ctx)
            when :mapping:
              res = args.collect{ |a| fctn.run(ctx.with_root(a)) }.flatten
            when :reduction:
              ctx.set_var('0', args.flatten)
              res = fctn.run(ctx)
          end
        end
        return res
      end

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
