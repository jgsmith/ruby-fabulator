require 'fabulator/action_lib'
require 'fabulator/core/actions/choose'
require 'fabulator/core/actions/for_each'
require 'fabulator/core/actions/variables'

module Fabulator
  module Core
  module Actions
  class Lib
    include ActionLib
    register_namespace FAB_NS

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

    mapping 'abs' do |ctx, arg, ns|
      arg.value.abs
    end

    mapping 'ceiling' do |ctx, arg, ns|
      arg.to(NUMERIC).value.to_d.ceil.to_r
    end

    mapping 'floor' do |ctx, arg, ns|
      arg.to(NUMERIC).value.to_d.floor.to_r
    end

    reduction 'sum', { :scaling => :log } do |ctx, args, ns|
      zero = ActionLib.find_op(args.first.vtype, :zero)
      if(zero && zero[:proc])
        res = zero[:proc].call(ctx)
      end
      res = 0 if res.nil?
      return [ res ] if args.empty?

      op = ActionLib.find_op(args.first.vtype, :plus)

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

    reduction 'avg' do |ctx, args, ns|
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

    reduction 'max', { :scaling => :log } do |ctx, args, ns|
      res = nil
      args.each do |a|
        res = a.to(NUMERIC).value if res.nil? || a.to(NUMERIC).value > res
      end

      [ctx.anon_node(res, NUMERIC)]
    end

    reduction 'min', { :scaling => :log } do |ctx, args, ns|
      res = nil
      args.each do |a|
        res = a.to(NUMERIC).value if res.nil? || a.to(NUMERIC).value < res
      end

      [ctx.anon_node(res, NUMERIC)]
    end

    function 'histogram' do |ctx, args, ns|
      acc = { }
      args.flatten.each do |a|
        acc[a.to_s] ||= 0
        acc[a.to_s] = acc[a.to_s] + 1
      end
      acc
    end

    reduction 'consolidate', { :scaling => :log } do |ctx, args, ns|
      acc = { }
      attrs = { }
      children = { }
      args.each do |a|
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

      ret = ctx.anon_node(nil)
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
    reduction 'concat', { :scaling => :log } do |ctx, args, ns|
      return '' if args.empty?
      [ args.collect{ |a| a.value.to_s}.join('') ]
    end

    #
    # f:string-join(node-set, joiner) => node
    #
    function 'string-join' do |ctx, args, ns|
      joiner = args[1].first.value.to_s
      [ args[0].collect{|a| a.value.to_s }.join(joiner) ]
    end

    #
    # f:substring(node-set, begin)
    # f:substring(node-set, begin, length)
    #
    function 'substring' do |ctx, args, ns|
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
    mapping 'string-length' do |ctx, arg, ns|
      arg.to_s.length
    end

    mapping 'normalize-space' do |ctx, arg, ns|
      arg.to_s.gsub(/^\s+/, '').gsub(/\s+$/,'').gsub(/\s+/, ' ')
    end

    mapping 'upper-case' do |ctx, arg, ns|
      arg.to_s.upcase
    end

    mapping 'lower-case' do |ctx, arg, ns|
      arg.to_s.downcase
    end

    function 'split' do |ctx, args, ns|
      div = args[1].first.to_s
      args[0].collect{ |a| a.to_s.split(div) }
    end

    function 'contains' do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')
      return args[0].collect{ |a| (a.to_s.include?(tgt) rescue false) }
    end

    function 'starts-with' do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')
      tgt_len = tgt.size - 1
      return args[0].collect{ |a| (a.to_s[0,tgt_len] == tgt rescue false) }
    end

    function 'ends-with' do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '').reverse
      tgt_len = tgt.size
      return args[0].collect{ |a| (a.to_s[-tgt_len,-1] == tgt rescue false) }
    end

    function 'substring-before' do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')
      return [ '' ] if tgt == ''

      return args[0].collect{ |a| (a.value.to_s.split(tgt,2))[0] }
    end

    function 'substring-after' do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')

      return args[0].collect{ |a| a.to_s } if tgt == ''

      return args[0].collect{ |a| a.to_s.include?(tgt) ? (a.to_s.split(tgt))[-1] : "" }
    end
    

    ###
    ### Regexes
    ###

    function 'matches' do |ctx, args, ns|
    end

    function 'replace' do |ctx, args, ns|
    end

    function 'tokenize' do |ctx, args, ns|
    end

    function 'keep' do |ctx, args, ns|
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

    function 'true', BOOLEAN do |ctx, args, ns|
      return [ ctx.anon_node( true, [ FAB_NS, 'boolean' ] ) ]
    end

    function 'false', BOOLEAN do |ctx, args, ns|
      return [ ctx.anon_node( false, [ FAB_NS, 'boolean' ] ) ]
    end

    mapping 'not' do |ctx, arg, ns|
      !arg.value
    end

    ###
    ### data node functions
    ###

    mapping 'name' do |ctx, arg, ns|
      arg.name || ''
    end

    mapping 'root' do |ctx, arg, ns|
      arg.root
    end

    mapping 'lang' do |ctx, arg, ns|
      # we want to track language for rdf purposes?
    end

    mapping 'path' do |ctx, arg, ns|
      arg.path
    end

    mapping 'dump' do |ctx, arg, ns|
      YAML::dump(
        arg.is_a?(Array) ? arg.collect{ |a| a.to_h } : arg.to_h 
      ) 
    end

    mapping 'eval' do |ctx, arg, ns|
      p = Fabulator::Expr::Parser.new
      e = arg.to_s
      pe = e.nil? ? nil : p.parse(e,ns)
      pe.nil? ? [] : pe.run(ctx)
    end

    ###
    ### Sequences
    ###

    mapping 'empty' do |ctx, arg, ns|
      arg.nil? || !arg.is_a?(Array) || arg.empty?
    end

    mapping 'exists' do |ctx, arg, ns|
      !(arg.nil? || !arg.is_a?(Array) || arg.empty?)
    end

    function 'reverse' do |ctx, args, ns|
      args.flatten.reverse
    end

    mapping 'zero-or-one' do |ctx, arg, ns|
      arg.is_a?(Array) && arg.size <= 1
    end

    mapping 'one-or-more' do |ctx, arg, ns|
      arg.is_a?(Array) && arg.size >= 1
    end

    mapping 'zero-or-one' do |ctx, arg, ns|
      arg.is_a?(Array) && arg.size == 1
    end

    reduction 'count' do |ctx, args, ns|
      args.size
    end

    ###
    ### Context
    ###

    function 'position', NUMERIC do |ctx, args, ns|
    end

    function 'last', BOOLEAN do |ctx, args, ns|
    end

    ###
    ### URIs
    ###
 
    mapping 'uri-prefix' do |ctx, arg, ns|
      res = [ ]
      prefix = arg.to_s
      # resolve prefix to href
      if ns[prefix]
        return ctx.anon_node( ns[prefix], [FAB_NS, 'string'])
      else
        return []
      end
    end
      

    ###
    ### Filters
    ###

    filter 'trim' do |c|
      v = c.value
      v.chomp!
      v.gsub!(/^\s*/,'')
      v.gsub!(/\s*$/,'')
      v.gsub!(/\s+/, ' ')
      c.value = v
      c
    end

    filter 'downcase' do |c|
      v = c.value
      v.downcase!
      c.value = v
      c
    end

    filter 'upcase' do |c|
      v = c.value
      v.upcase!
      c.value = v
      c
    end

    filter 'integer' do |c|
      v = c.value
      v = v.to_i.to_s
      c.value = v
      c
    end

    filter 'decimal' do |c|
      v = c.value
      v = v.to_f.to_s
      c.value = v
      c
    end

  end
  end
  end
end
