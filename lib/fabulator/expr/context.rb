module Fabulator
  module Expr
    class Context

  def initialize(parent_c = nil, xml = nil)
    @parent = parent_c
    @run_time_parent = nil
    @ns = { }
    @attributes = { }
    @variables = { }
    @position = nil
    @last = nil

    if parent_c.nil?
       if xml.nil? || (xml.root rescue nil).nil?
         roots = { }
         roots['data'] = Fabulator::Expr::Node.new('data', roots, nil, [])
         @root = roots['data']
       end
    end

    if !xml.nil?
      if xml.is_a?(self.class)
        @run_time_parent = xml
      else
        parser = Fabulator::Expr::Parser.new

        xml.namespaces.each do |ns|
          @ns[ns.prefix] = ns.href
        end
        begin
          @ns[''] = xml.namespaces.default.href
        rescue
        end

        xml.each_attr do |attr|
          v = attr.value
          if !v.nil?
            @attributes[attr.ns.href.to_s] ||= {}
            @attributes[attr.ns.href.to_s][attr.name.to_s] = v
          end
        end
      end
    end
  end

  def last?
    return @last unless @last.nil?
    return @last if @run_time_parent.nil?
    return @run_time_parent.last?
  end

  def last=(l)
    @last = !!l
  end

  def position
    return @position unless @position.nil?
    return @position if @run_time_parent.nil?
    return @run_time_parent.position
  end

  def position=(p)
    @position = p
  end

  def merge(s = nil)
    self.class.new(self, s)
  end

  def attribute(ns, attr, popts = { })
    opts = { :static => !@run_time_parent.nil? && !self.root.nil? }.update(popts)
    value = nil
    if @attributes.nil? || @attributes[ns].nil? || @attributes[ns].empty? || @attributes[ns][attr].nil?
      if opts[:inherited]
        value = @parent.nil? ? nil : @parent.attribute(ns, attr, opts)
      end
    else
      value = @attributes[ns][attr]
    end
    if value.nil? && !opts[:default].nil?
      value = opts[:default]
    end

    if !value.nil? && value.is_a?(String)
      e = nil
      if !opts[:eval]
        if value =~ /^\{(.*)\}$/
          e = $1
        end
      else
        e = value
      end
      if !e.nil?
        p = Fabulator::Expr::Parser.new
        value = p.parse(e, self)
      else
        value = Fabulator::Expr::Literal.new(value, [ FAB_NS, value =~ /^\d+$/ ? 'numeric' : value =~ /^\d*\.\d+$/ || value =~ /^\d+\.\d*$/ ? 'numeric' : 'string' ])
      end
      if opts[:static]
        value = value.run(self).collect{ |v| v.value }
        if value.empty?
          value = nil
        elsif value.size == 1
          value = value.first
        end
      end
    end

    value
  end

  def get_select(default = nil)
    self.attribute(FAB_NS, 'select', { :eval => true, :static => false, :default => default })
  end

  def with_root(r)
    ctx = self.class.new(self)
    ctx.root = r
    ctx
  end

  def root
    if @root.nil?
      return @run_time_parent.nil? ? 
             ( @parent.nil? ? nil : @parent.root ) : @run_time_parent.root
    end
    @root
  end

  def root=(r)
    @root = r
  end

  def get_var(v)
    if !@variables.has_key?(v)
      if @run_time_parent.nil?
        if @parent.nil?
          nil
        else
          @parent.get_var(v)
        end
      else
        @run_time_parent.get_var(v)
      end
    else
      @variables[v]
    end
  end

  def set_var(v,vv)
    @variables[v] = vv
  end

  def get_ns(n)
    return @ns[n] if @ns.has_key?(n)
    return @parent.get_ns(n) unless @parent.nil?
    return nil
  end

  def set_ns(n,h)
    @ns[n] = h
  end

  def each_namespace(&block)
    if !@parent.nil?
      @parent.each_namespace do |k,v|
        yield k, v
      end
    end
    @ns.each_pair do |k,v|
       yield k, v
    end
  end

  def eval_expression(selection)
    if selection.is_a?(String)
      p = Fabulator::Expr::Parser.new
      selection = p.parse(selection, self)
    end

    if selection.nil?
      res = [ ]
    else
      # run selection against current context
      res = selection.run(self)
    end
    return res
  end

  def run(action, autovivify = false)
    action.run(self, autovivify)
  end

  def traverse_path(path, autovivify = false)
    return [ self.root ] if path.nil? || path.is_a?(Array) && path.empty?
                         
    path = [ path ] unless path.is_a?(Array)

    current = [ self.root ]

    path.each do |c|
      set = [ ]
      current.each do |cc|
        if c.is_a?(String)
          cset = cc.children(c)
        else
          cset = c.run(self.with_root(cc), autovivify)
        end
        if cset.nil? || cset.empty?
          if autovivify
            if c.is_a?(String)
              cset = [ cc.create_child(c) ]
            else
              cset = [ c.create_node(cc) ]
            end
          end
        end
        set = set + cset
      end
      current = set
    end
    return current
  end

  def set_value(p, v)
    if p.is_a?(String) || v.is_a?(String)
      parser = Fabulator::Expr::Parser.new   
      p = parser.parse(p,self) if p.is_a?(String)
      v = parser.parse(v,self) if v.is_a?(String)
    end
        
    return [] if p.nil?
        
    p = [ p ] unless p.is_a?(Array)
          
    ret = [ ]

    p.each do |pp|
      tgts = pp.run(self, true)
      src = nil
      if !v.nil?
        src = v.run(self)
      end 

      tgts.each do |tgt|
        tgt.prune
        if src.nil? || src.empty?
          tgt.value = nil
          ret << tgt
        elsif src.size == 1
          tgt.copy(src.first)
          ret << tgt
        else
          pp = tgt.parent
          nom = tgt.name
          pp.prune(pp.children(nom))
          src.each do |s|
            tgt = pp.create_child(nom,nil)
            tgt.copy(s)
            ret << tgt
          end
        end
      end
    end
    ret
  end

  def get_values(ln = nil)
    return [] if ln.nil?
    self.eval_expression(ln).collect{ |c| c.value} - [ nil ]
  end

  def merge_data(d,p = nil)
    # we have a hash or array based on root (r)
    if p.nil?
      root_context = [ self.root ]
    else
      root_context = self.traverse_path(p,true)
    end
    if root_context.size > 1
      # see if we need to prune
      new_rc = [ ]
      root_context.each do |c|
        if c.children.size == 0 && c.value.nil?
          c.parent.prune(c) if c.parent
        else
          new_rc << c
        end
      end
      if new_rc.size > 0
        raise "Unable to merge data into multiple places simultaneously"
      else
        root_context = new_rc
      end
    else
      root_context = root_context.first
    end
    if d.is_a?(Array)
      node_name = root_context.name
      root_context = root_context.parent
      # get rid of empty children so we don't have problems later
      root_context.children.each do |c|
        if c.children.size == 0 && c.name == node_name && c.value.nil?
          c.parent.prune(c)
        end
      end
      d.each do |i|
        c = root_context.create_child(node_name)
        self.with_root(c).merge_data(i)
      end
    elsif d.is_a?(Hash)
      d.each_pair do |k,v|
        bits = k.split('.')
        c = self.with_root(root_context).traverse_path(bits,true).first
        if v.is_a?(Hash) || v.is_a?(Array)
          self.with_root(c).merge_data(v)
        else
          c.value = v
        end
      end
    else
      c = root_context.parent.create_child(root_context.name, d)
    end
  end

  def compile_actions(xml)
    actions = Fabulator::Expr::StatementList.new
    local_ctx = self.merge(xml)
    xml.each_element do |e|
      ns = e.namespaces.namespace.href
      next unless Fabulator::ActionLib.namespaces.include?(ns)
      if ns == FAB_NS && e.name == 'ensure'
        actions.add_ensure(local_ctx.compile_actions(e))
      elsif ns == FAB_NS && e.name == 'catch'
        actions.add_catch(local_ctx.compile_action(e))
      else
        actions.add_statement(local_ctx.compile_action(e)) # rescue nil)
      end
    end
    return actions
  end

  def compile_action(e)
    ns = e.namespaces.namespace.href
    return unless Fabulator::ActionLib.namespaces.include?(ns)
    Fabulator::ActionLib.namespaces[ns].compile_action(e, self)
  end

  def in_context(&block)
    ctx = self.merge
    yield ctx
  end

  def with(ctx2, &block)
    ctx = self.merge(ctx2)
    yield ctx
  end

  def run_filter(ns, name)
    handler = Fabulator::ActionLib.namespaces[ns]
    return [] if handler.nil?
    handler.run_filter(self, name)
  end

    end
  end
end
