require 'fabulator/tag_lib'
require 'fabulator/core/actions/choose'
require 'fabulator/core/actions/for_each'
require 'fabulator/core/actions/variables'

module Fabulator
  module Core
  class Lib < TagLib
    namespace FAB_NS

    structural :application, Structurals::StateMachine
    structural :view, Structurals::State
    structural 'goes-to', Structurals::Transition
    structural :params, Structurals::Group
    structural :group, Structurals::Group
    structural :param, Structurals::Parameter
    structural :value, Structurals::Constraint
    structural :constraint, Structurals::Constraint
    structural :filter, Structurals::Filter

    structural :sort, Actions::Sort
    structural :when, Actions::When
    structural :otherwise, Actions::When

    action :choose, Actions::Choose
    action 'for-each', Actions::ForEach
    action 'value-of', Actions::ValueOf
    action :value, Actions::Value
    action :variable, Actions::Variable
    action :if, Actions::If
    action 'go-to', Actions::Goto
    action :raise, Actions::Raise
    action :div, Actions::Block
    action :catch, Actions::Catch

    presentations do
      transformations_into.html do
        xslt_from_file File.join(File.dirname(__FILE__), "..", "..", "..", "xslt", "form.xsl")
      end

      interactive :text
      interactive :asset
      interactive :selection
      interactive :password
      interactive :submission

      structural :form
      structural :container
      structural :group
      structural :option
    end

    ###
    ### core types
    ###

    has_type :boolean do
      going_to [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |i|
          i.root.value ? 'true' : ''
        end
      end

      going_to [ FAB_NS, 'numeric' ] do
        weight 1.0
        converting do |i|
          Rational.new(i.root.value ? 1 : 0, 1)
        end
      end
    end

    has_type :string do
      going_to [ FAB_NS, 'boolean' ] do
        weight 0.0001
        converting do |s|
          !(s.root.value.nil? || s.root.value == '' || s.root.value =~ /^\s*$/)
        end
      end

      going_to [ FAB_NS, 'html' ] do
        weight 1.0
        converting do |s|
          s.root.value.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
        end
      end
    end

    has_type :html do
    end

    has_type :uri do
      going_to [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |u|
          u.root.get_attribute('namespace').value + u.root.get_attribute('name').value
        end
      end

      coming_from [ FAB_NS, 'string'] do
        weight 1.0
        converting do |u|
          p = u.root.value
          ns = nil
          name = nil
          if p =~ /^([a-zA-Z_][-a-zA-Z0-9_.]*):([a-zA-Z_][-a-zA-Z0-9_.]*)$/
            ns_prefix = $1
            name = $2
            ns = u.get_ns(ns_prefix)
          else
            p =~ /^(.*?)([a-zA-Z_][-a-zA-Z0-9_.]*)$/
            ns = $1
            name = $2
          end
          r = u.root.anon_node(nil)
          r.set_attribute('namespace', ns)
          r.set_attribute('name', name)
          r
        end
      end
    end

    has_type :numeric do
      going_to [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |n|
          (n.root.value % 1 == 0 ? n.root.value.to_i : n.root.value.to_d).to_s
        end
      end

      going_to [ FAB_NS, 'boolean' ] do
        weight 0.0001
        converting do |n|
          n.root.value != 0
        end
      end
    end

    has_type :expression do
      coming_from [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |e|
          p = Fabulator::Expr::Parser.new
          c = e.root.value
          c.nil? ? nil : p.parse(c,e)
        end
      end
    end
    
    has_type "date-time".to_sym do
      coming_from [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |e|
          DateTime.parse(e.root.value)
        end
      end
      
      going_to [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |e|
        end
      end
      
      method :PLUS, { :types => [ :duration ] } do |ctx, args|
        ctx.root.anon_node(args.first.value + args.last.value, [ FAB_NS, 'date-time' ])
      end
      
      method :MINUS do |ctx, args|
      end
      
      method :LT do |ctx, args|
      end
      
      method :GT do |ctx, args|
      end
      
      method :LTE do |ctx, args|
      end
      
      method :GTE do |ctx, args|
      end
      
      method :EQ do |ctx, args|
      end
      
      method :NEQ do |ctx, args|
      end
    end
    
    has_type :duration do
      coming_from [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |e|
        end
      end
      
      going_to [ FAB_NS, 'string' ] do
        weight 1.0
        converting do |e|
        end
      end
      
      coming_from [ FAB_NS, 'numeric' ] do
        weight 1.0
        converting do |e|
          e.root.value
        end
      end
      
      going_to [ FAB_NS, 'numeric' ] do
        weight 1.0
        converting do |e|
          e.root.value
        end
      end
      
      method :PLUS, { :types => [ 'date-time' ] } do |ctx, args|
        ctx.root.anon_node(args.first.value + args.last.value, args.last.vtype)
      end
      
      method :MINUS do |ctx, args|
        ctx.root.anon_node(args.first.value - args.last.value, args.last.vtype)
      end
    end

    ###
    ### Numeric functions
    ###

    NUMERIC = [ FAB_NS, 'numeric' ]

    mapping 'abs' do |ctx, arg|
      arg.value.abs
    end

    mapping 'ceiling' do |ctx, arg|
      arg.to(NUMERIC).value.to_d.ceil.to_r
    end

    mapping 'floor' do |ctx, arg|
      arg.to(NUMERIC).value.to_d.floor.to_r
    end

    mapping 'random' do |ctx, arg|
      v = arg.to(NUMERIC).value.to_i
      if v <= 0
        (0.0).to_d.to_r
      else
        (1.0*rand(v) + 1.0).floor.to_r
      end
    end

    reduction 'sum', { :scaling => :log, :consolidation => :sum } do |ctx, args|
      zero = TagLib.find_op(args.first.vtype, :zero)
      if(zero && zero[:proc])
        res = zero[:proc].call(ctx)
      end
      res = 0 if res.nil?
      return [ res ] if args.empty?

      op = TagLib.find_op(args.first.vtype, :plus)

      if op.nil? || op[:proc].nil?
        args.each do |a|
          res = res + a.value
        end
      else
        args.each do |a|
          res = op[:proc].call(res, a)
        end
      end
      [ res ]
    end

    reduction 'avg', { :scaling => :flat } do |ctx, args|
      res = 0.0
      n = 0.0
      args.each do |a|
        res = res + a.value.to_f
        n = n + 1.0
      end
      res = res / n if n > 0
      if res.floor == res
        [ res.to_i ]
      else
        [ res ]
      end
    end

    reduction 'max', { :scaling => :log, :consolidation => :max } do |ctx, args|
      res = nil
      args.each do |a|
        res = a.to(NUMERIC).value if res.nil? || a.to(NUMERIC).value > res
      end

      [ctx.root.anon_node(res, NUMERIC)]
    end

    reduction 'min', { :scaling => :log, :consolidation => :min } do |ctx, args|
      res = nil
      args.each do |a|
        res = a.to(NUMERIC).value if res.nil? || a.to(NUMERIC).value < res
      end

      [ctx.root.anon_node(res, NUMERIC)]
    end

    reduction 'histogram', { :scaling => :log } do |ctx, args|
      acc = { }
      args.flatten.each do |a|
        acc[a.to_s] ||= 0
        acc[a.to_s] = acc[a.to_s] + 1
      end
      acc
    end

    # TODO: make 'consolidate' a general-purpose function that translates
    #   into the consolidation function of reductions
    #
    # the code here is the consolidation function for histogram
    # f:sum is the consolidation function for f:sum
    #
    consolidation 'histogram', { :scaling => :log } do |ctx, args|
      acc = { }
      attrs = { }
      children = { }
      args.flatten.each do |a|
        a.children.each do |c|
          acc[c.name] ||= 0
          acc[c.name] = acc[c.name] + c.value
          attrs[c.name] ||= { }
          c.attributes.each do |a|
            attrs[c.name][a.name] ||= [ ]
            attrs[c.name][a.name] << a.value
          end
          children[c.name] ||= [ ]
          children[c.name] += c.children
        end
      end

      ret = ctx.root.anon_node(nil)
      acc.each_pair do |tok, cnt|
        t = ret.create_child(tok, cnt, [FAB_NS, 'numeric'])
        attrs[tok].each_pair do |a, vs|
          t.set_attribute(a, vs.flatten)
        end
        children[tok].each do |child|
          t.add_child(child.clone)
        end
      end
      ret
    end
    
    ###
    ### Date functions
    ###
    
    function 'now' do |ctx, args|
      ctx.root.anon_node(Time.now(), [ FAB_NS, 'date-time' ])
    end
    
    function 'today' do |ctx, args|
      ctx.root.anon_node(Time.now(), [ FAB_NS, 'date-time'])
    end
    
    mapping 'years-from-duration' do |ctx, arg|
      d = arg.to([FAB_NS, 'duration'])
      return 0 if d.nil?
      (d.value / 365).floor
    end

    mapping 'months-from-duration' do |ctx, arg|
      d = arg.to([FAB_NS, 'duration'])
      return 0 if d.nil?
      ((d.value - 365*(d.value/365).floor)/30.0).floor
    end
    
    mapping 'days-from-duration' do |ctx, arg|
      d = arg.to([FAB_NS, 'duration'])
      return 0 if d.nil?
      m = ((d.value - 365*(d.value/365).floor)/30.0)
      ((m - m.floor)*30.0).floor
    end
    
    mapping 'hours-from-duration' do |ctx, arg|
      d = arg.to([FAB_NS, 'duration'])
      return 0 if d.nil?
      h = d.value - d.value.floor
      (h*24.0).floor
    end
    
    mapping 'minutes-from-duration' do |ctx, arg|
      d = arg.to([FAB_NS, 'duration'])
      return 0 if d.nil?
      h = d.value - d.value.floor
      ((h*24.0 - (h*24.0).floor)*60.0).floor
    end
    
    mapping 'seconds-from-duration' do |ctx, arg|
      d = arg.to([FAB_NS, 'duration'])
      return 0 if d.nil?
      h = d.value - d.value.floor
      m = ((h*24.0 - (h*24.0).floor)*60.0)
      (m - m.floor)*60.0
    end
    
    mapping 'hours-from-time' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.hour
    end
    
    mapping 'minutes-from-time' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.min
    end
    
    mapping 'seconds-from-time' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.sec + t.value.sec_fraction
    end
    
    mapping 'year-from-date' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.year
    end
    
    mapping 'month-from-date' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.mon
    end
    
    mapping 'day-from-date' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.mday
    end
    
    mapping 'timezone' do |ctx, arg|
      t = arg.to([FAB_NS, 'date-time'])
      return 0 if t.nil?
      t.value.offset * 24
    end
    
    mapping 'day-duration' do |ctx, arg|
      ctx.root.anon_node(arg.to([FAB_NS, 'numeric']).value.to_f, [ FAB_NS, :duration ])
    end
    
    mapping 'hour-duration' do |ctx, arg|
      ctx.root.anon_node(arg.to([FAB_NS, 'numeric']).value.to_f / 24.0, [ FAB_NS, :duration ])
    end
    
    mapping 'minute-duration' do |ctx, arg|
      ctx.root.anon_node(arg.to([FAB_NS, 'numeric']).value.to_f / (24.0 * 60.0), [ FAB_NS, :duration ])
    end
    
    mapping 'second-duration' do |ctx, arg|
      ctx.root.anon_node(arg.to([FAB_NS, 'numeric']).value.to_f / (24.0 * 60.0 * 60.0), [ FAB_NS, :duration ])
    end
    
    ###
    ### String functions
    ###

    STRING = [ FAB_NS, 'string' ]
    BOOLEAN = [ FAB_NS, 'boolean' ]

    #
    # f:concat(node-set) => node
    #
    reduction 'concat', { :scaling => :log, :consolidation => :concat } do |ctx, args|
      return '' if args.empty?
      [ args.collect{ |a| a.value.to_s}.join('') ]
    end

    #
    # f:string-join(node-set, joiner) => node
    #
    function 'string-join' do |ctx, args|
      joiner = args[1].first.value.to_s
      [ args[0].collect{|a| a.value.to_s }.join(joiner) ]
    end

    #
    # f:substring(node-set, begin)
    # f:substring(node-set, begin, length)
    #
    function 'substring' do |ctx, args|
      first = args[1].first.value
      if args.size == 3
        last = args[2].first.value
        return [ args[0].collect{ |src| s = src.value.to_s; s.length > first + last - 2 ? s[first-1, s.length-1] : s[first-1, first + last - 2] } ]
      else
        return [ args[0].collect{ |src| s = src.value.to_s; s[first-1, s.length-1] } ]
      end
    end

    #
    # f:string-length(node-list) => node-list
    #
    mapping 'string-length' do |ctx, arg|
      (arg.to_s.length rescue 0)
    end

    mapping 'normalize-space' do |ctx, arg|
      arg.to_s.gsub(/^\s+/, '').gsub(/\s+$/,'').gsub(/\s+/, ' ')
    end

    mapping 'upper-case' do |ctx, arg|
      arg.to_s.upcase
    end

    mapping 'lower-case' do |ctx, arg|
      arg.to_s.downcase
    end

    function 'split' do |ctx, args|
      div = args[1].first.to_s
      args[0].collect{ |a| a.to_s.split(div) }
    end

    function 'contains?' do |ctx, args|
      tgt = (args[1].first.to_s rescue '')
      return args[0].collect{ |a| (a.to_s.include?(tgt) rescue false) }
    end

    function 'starts-with?' do |ctx, args|
      tgt = (args[1].first.to_s rescue '')
      tgt_len = tgt.size
      return args[0].collect{ |a| (a.to_s[0,tgt_len] == tgt rescue false) }
    end

    function 'ends-with?' do |ctx, args|
      tgt = (args[1].first.to_s rescue '').reverse
      tgt_len = tgt.size
      return args[0].collect{ |a| (a.to_s[-tgt_len,-1] == tgt rescue false) }
    end

    function 'substring-before' do |ctx, args|
      tgt = (args[1].first.to_s rescue '')
      return [ '' ] if tgt == ''

      return args[0].collect{ |a| (a.value.to_s.split(tgt,2))[0] }
    end

    function 'substring-after' do |ctx, args|
      tgt = (args[1].first.to_s rescue '')

      return args[0].collect{ |a| a.to_s } if tgt == ''

      return args[0].collect{ |a| a.to_s.include?(tgt) ? (a.to_s.split(tgt))[-1] : "" }
    end

    function 'index-of' do |ctx, args|
      tgt = (args[1].first.to_s rescue ' ')
      start = (args[2].first.to(NUMERIC, ctx).value.to_i rescue 0)
      ret = [ ]
      args[0].collect{ |a| 
        as = a.to_s
        ret << as.index(tgt, start)
        while !ret.last.nil?
          ret << as.index(tgt, ret.last)
        end
        ret -= [ nil ]
      }
      ret
    end

    ###
    ### Regexes
    ###

    function 'keep' do |ctx, args|
      # args[0] - strings to operate on
      # args[1] - char classes to keep: alpha, numeric, space, punctuation, control
      # we replace with 'space' if no args[2]
      replacement = args.size > 2 ? args[2].first.to_s : ' '
      classes = args[1].collect { |a|
        case a.to_s
          when 'alpha' then 'a-zA-Z'
          when 'lower' then 'a-z'
          when 'upper' then 'A-Z'
          when 'numeric' then '0-9'
          when 'space' then ' '
          when 'punctuation' then ''
          when 'control' then ''
          else ''
        end
      }.join('')

      args[0].collect{ |a|
        a.to_s.gsub(/[^#{classes}]+/, replacement)
      }
    end
      

    ###
    ### Boolean
    ###
 
    function 'true', BOOLEAN do |ctx, args|
      return [ ctx.root.anon_node( true, [ FAB_NS, 'boolean' ] ) ]
    end

    function 'false', BOOLEAN do |ctx, args|
      return [ ctx.root.anon_node( false, [ FAB_NS, 'boolean' ] ) ]
    end

    mapping 'not' do |ctx, arg|
      !arg.value
    end

    ###
    ### data node functions
    ###

    mapping 'name' do |ctx, arg|
      arg.name || ''
    end

    mapping 'root' do |ctx, arg|
      arg.root
    end

    mapping 'lang' do |ctx, arg|
      # we want to track language for rdf purposes?
    end

    mapping 'path' do |ctx, arg|
      arg.path
    end

    mapping 'dump' do |ctx, arg|
      YAML::dump(
        arg.is_a?(Array) ? arg.collect{ |a| a.to_h } : arg.to_h 
      ) 
    end

    mapping 'eval' do |ctx, arg|
      p = Fabulator::Expr::Parser.new
      if arg.vtype.join('') == FAB_NS+'expression'
        return arg.value.run(ctx, true)
      else
        e = arg.to_s
        pe = e.nil? ? nil : p.parse(e,ctx)
        return pe.nil? ? [] : pe.run(ctx, true)
      end
    end

    ###
    ### Sequences
    ###

    reduction 'empty?' do |ctx, arg|
      ctx.root.anon_node(arg.nil? || !arg.is_a?(Array) || arg.empty?, [ FAB_NS, 'boolean' ])
    end
    
    consolidation 'empty?' do |ctx, arg|
      arg.each do |a| 
        if !a.to([FAB_NS, 'boolean']).value
          return [ ctx.root.anon_node(false, [ FAB_NS, 'boolean' ] ) ]
        end
      end
      return [ ctx.root.anon_node(true, [ FAB_NS, 'boolean' ] ) ]
    end

    reduction 'exists?' do |ctx, arg|
      ctx.root.anon_node(!(arg.nil? || !arg.is_a?(Array) || arg.empty?), [ FAB_NS, 'boolean' ])
    end
    
    consolidation 'exists?' do |ctx, arg|
      arg.each do |a| 
        if !a.to([FAB_NS, 'boolean']).value
          return [ ctx.root.anon_node(false, [ FAB_NS, 'boolean' ] ) ]
        end
      end
      return [ ctx.root.anon_node(true, [ FAB_NS, 'boolean' ] ) ]
    end

    function 'reverse' do |ctx, args|
      args.flatten.reverse
    end

    reduction 'zero-or-one?' do |ctx, arg|
      arg.is_a?(Array) && arg.size <= 1
    end

    reduction 'one-or-more?' do |ctx, arg|
      arg.is_a?(Array) && arg.size >= 1
    end
    
    consolidation 'one-or-more?' do |ctx, arg|
      arg.each do |a| 
        if !a.to([FAB_NS, 'boolean']).value
          return [ ctx.root.anon_node(false, [ FAB_NS, 'boolean' ] ) ]
        end
      end
      return [ ctx.root.anon_node(true, [ FAB_NS, 'boolean' ] ) ]
    end

    reduction 'only-one?' do |ctx, arg|
      [ ctx.root.anon_node(arg.is_a?(Array) && arg.size == 1, [FAB_NS, 'boolean']) ]
    end

    reduction 'count', { :consolidation => :sum } do |ctx, args|
      args.size
    end

    function 'first' do |ctx, args|
      if args.size == 1 && args.vtype.join('') == FAB_NS + 'tuple'
        args.value.first
      else
        args.first
      end
    end

    function 'last' do |ctx, args|
      if args.size == 1 && args.vtype.join('') == FAB_NS + 'tuple'
        args.value.last
      else
        args.last
      end
    end

    function 'all-but-first' do |ctx, args|
      if args.size == 1 && args.vtype.join('') == FAB_NS + 'tuple'
        if args.value.size > 1
          args.value[1 .. args.value.size-1]
        else
          []
        end
      elsif args.size > 1
        args[1 .. args.size-1]
      else
        []
      end
    end

    function 'all-but-last' do |ctx, args|
      if args.size == 1 && args.vtype.join('') == FAB_NS + 'tuple'
        if args.value.size > 1
          args.value[0 .. args.value.size-2]
        else
          []
        end
      elsif args.size > 1
        args[0 .. args.size-2]
      else
        []
      end
    end

    ###
    ### Context
    ###

    function 'position', NUMERIC do |ctx, args|
      ctx.position
    end

    function 'last?', BOOLEAN do |ctx, args|
      ctx.last?
    end

    function 'first?', BOOLEAN do |ctx, args|
      ctx.position == 1
    end

    ###
    ### URIs
    ###
 
    mapping 'uri-prefix' do |ctx, arg|
      res = [ ]
      prefix = arg.to_s
      # resolve prefix to href
      if ctx.get_ns(prefix)
        return ctx.root.anon_node( ctx.get_ns(prefix), [FAB_NS, 'string'])
      else
        return []
      end
    end
      

    ###
    ### Filters
    ###

    filter 'trim' do |c|
      v = c.root.value
      if !v.nil?
        v.chomp!
        v.gsub!(/^\s*/,'')
        v.gsub!(/\s*$/,'')
        v.gsub!(/\s+/, ' ')
      end
      v
    end

    filter 'downcase' do |c|
      v = c.root.value
      if !v.nil?
        v.downcase!
        c.root.value = v
      end
      c
    end

    filter 'upcase' do |c|
      v = c.root.value
      if !v.nil?
        v.upcase!
        c.root.value = v
      end
      c
    end

    filter 'integer' do |c|
      v = c.root.value
      if !v.nil?
        v = v.to_i.to_s
        c.root.value = v
      end
      c
    end

    filter 'decimal' do |c|
      v = c.root.value
      if !v.nil?
        v = v.to_f.to_s
        c.root.value = v
      end
      c
    end

  end
  end
end
