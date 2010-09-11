require 'fabulator/tag_lib'
require 'fabulator/core/actions/choose'
require 'fabulator/core/actions/for_each'
require 'fabulator/core/actions/variables'

module Fabulator
  module Core
  module Actions
  class Lib < TagLib
    namespace FAB_NS

    structural 'application', Fabulator::Core::StateMachine
    structural 'view', Fabulator::Core::State
    structural 'goes-to', Fabulator::Core::Transition
    #structural 'before', 
    #structural 'after', 
    structural 'params', Fabulator::Core::Group
    structural 'group', Fabulator::Core::Group
    structural 'param', Fabulator::Core::Parameter
    structural 'value', Fabulator::Core::Constraint
    structural 'constraint', Fabulator::Core::Constraint
    structural 'filter', Fabulator::Core::Filter
    structural 'sort', Sort
    structural 'when', When
    structural 'otherwise', When


    action 'choose', Choose
    action 'for-each', ForEach
    action 'value-of', ValueOf
    action 'value', Value
    action 'while', While
    action 'considering', Considering
    action 'variable', Variable
    action 'if', If
    action 'go-to', Goto
    action 'raise', Raise
    action 'div', Block
    action 'catch', Catch
    action 'super', Super

    ###
    ### core types
    ###

    register_type 'boolean', {
      :ops => {
      },
      :to => [
        { :type => [ FAB_NS, 'string' ],
          :weight => 1.0,
          :convert => lambda { |i| i.value ? 'true' : '' }
        },
        { :type => [ FAB_NS, 'numeric' ],
          :weight => 1.0,
          :convert => lambda{ |i| Rational.new(i.value ? 1 : 0, 1) }
        },
      ]
    }

    register_type 'string', {
      :ops => {
        #:plus => {
        #},
        :minus => { 
          :proc => lambda { |a,b| a.split(b).join('')} 
        },
        :mpy => {
          :args => [ [ FAB_NS, 'string' ], [ FAB_NS, 'integer' ] ],
          :proc => lambda { |a,b| a * b }
        },
        :lt => { },
        :eq => { },
      },
      :to => [
        { :type => [ FAB_NS, 'boolean' ],
          :weight => 0.0001,
          :convert => lambda { |s| !(s.value.nil? || s.value == '' || s.value =~ /\s*/) }
        },
        { :type => [ FAB_NS, 'html' ],
          :weight => 1.0,
          :convert => lambda { |s| s.value.gsub(/&/, '&amp;').gsub(/</, '&lt;') }
        },
      ],
    }

    register_type 'uri', {
      :to => [
        { :type => [ FAB_NS, 'string' ],
          :weight => 1.0,
          :convert => lambda { |u| u.get_attribute('namespace').value + u.get_attribute('name').value }
        }
      ]
    }

    register_type 'numeric', {
      :ops => {
        #:plus => { },
        #:minus => { },
        #:mpy => { },
        #:div => { },
        #:mod => { },
        #:lt => { },
        #:eq => { },
      },
      :to => [
        { :type => [ FAB_NS, 'string' ],
          :weight => 1.0,
          :convert => lambda { |n| (n.value % 1 == 0 ? n.value.to_i : n.value.to_d).to_s }
        },
        { :type => [ FAB_NS, 'boolean' ],
          :weight => 0.0001,
          :convert => lambda { |n| n.value != 0 }
        },
      ],
    }

    register_type 'expression', {
    }

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

    reduction 'sum', { :scaling => :log } do |ctx, args|
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

    reduction 'max', { :scaling => :log } do |ctx, args|
      res = nil
      args.each do |a|
        res = a.to(NUMERIC).value if res.nil? || a.to(NUMERIC).value > res
      end

      [ctx.root.anon_node(res, NUMERIC)]
    end

    reduction 'min', { :scaling => :log } do |ctx, args|
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
    ### String functions
    ###

    STRING = [ FAB_NS, 'string' ]
    BOOLEAN = [ FAB_NS, 'boolean' ]

    #
    # f:concat(node-set) => node
    #
    reduction 'concat', { :scaling => :log } do |ctx, args|
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
        return [ args[0].collect{ |src| src.value.to_s.substr(first, last) } ]
      else
        return [ args[0].collect{ |src| src.value.to_s.substr(first) } ]
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

    function 'contains' do |ctx, args|
      tgt = (args[1].first.to_s rescue '')
      return args[0].collect{ |a| (a.to_s.include?(tgt) rescue false) }
    end

    function 'starts-with' do |ctx, args|
      tgt = (args[1].first.to_s rescue '')
      tgt_len = tgt.size - 1
      return args[0].collect{ |a| (a.to_s[0,tgt_len] == tgt rescue false) }
    end

    function 'ends-with' do |ctx, args|
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
          when 'alpha': 'a-zA-Z'
          when 'lower': 'a-z'
          when 'upper': 'A-Z'
          when 'numeric': '0-9'
          when 'space': ' '
          when 'punctuation': ''
          when 'control': ''
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
        return arg.value.run(ctx)
      else
        e = arg.to_s
        pe = e.nil? ? nil : p.parse(e,ctx)
        return pe.nil? ? [] : pe.run(ctx)
      end
    end

    ###
    ### Sequences
    ###

    mapping 'empty' do |ctx, arg|
      arg.nil? || !arg.is_a?(Array) || arg.empty?
    end

    mapping 'exists' do |ctx, arg|
      !(arg.nil? || !arg.is_a?(Array) || arg.empty?)
    end

    function 'reverse' do |ctx, args|
      args.flatten.reverse
    end

    mapping 'zero-or-one' do |ctx, arg|
      arg.is_a?(Array) && arg.size <= 1
    end

    mapping 'one-or-more' do |ctx, arg|
      arg.is_a?(Array) && arg.size >= 1
    end

    mapping 'zero-or-one' do |ctx, arg|
      arg.is_a?(Array) && arg.size == 1
    end

    reduction 'count', { :consolidation => :sum } do |ctx, args|
      args.size
    end

    ###
    ### Context
    ###

    function 'position', NUMERIC do |ctx, args|
      ctx.position
    end

    function 'last', BOOLEAN do |ctx, args|
      ctx.last?
    end

    function 'first', BOOLEAN do |ctx, args|
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
end
