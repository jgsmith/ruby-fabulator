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


    ###
    ### Numeric functions
    ###

    NUMERIC = [ FAB_NS, 'numeric' ]

    function 'abs', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      args[0].collect { |i|
        i.value.abs
      }
    end

    function 'ceiling', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      args[0].collect { |i|
        i.value.to_d.ceil.to_r
      }
    end

    function 'floor', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      args[0].collect { |i|
        i.value.to_d.floor.to_r
      }
    end

    function 'sum', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      res = ActionLib.find_op(args[0].first.vtype, :zero)
      res = 0 if res.nil?
      return [ res ] if args.empty?
      return args[1] if args[0].empty? && args.size > 1

      op = ActionLib.find_op(args[0].first.vtype, :plus)

      if op.nil? || op[:proc].nil?
        args[0].each do |a|
          #puts "adding #{YAML::dump(a)}"
          res = res + a.value
        end
      else
        args[0].each do |a|
          res = op[:proc].call(res, a)
        end
      end
      [ res ]
    end

    function 'avg', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      res = 0.0
      n = 0.0
      args.first.each do |a|
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

    function 'max', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      res = nil
      args[0].each do |a|
        res = a.value.to_f if res.nil? || a.value.to_f > res
      end

      [res]
    end

    function 'min', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      res = nil
      args[0].each do |a|
        res = a.value.to_f if res.nil? || a.value.to_f < res
      end

      [res]
    end

    function 'histogram', NUMERIC, [ NUMERIC ] do |ctx, args, ns|
      acc = { }
      args[0].each do |a|
        acc[a.to_s] ||= 0
        acc[a.to_s] = acc[a.to_s] + 1
      end
      acc
    end

    ###
    ### String functions
    ###

    STRING = [ FAB_NS, 'string' ]
    BOOLEAN = [ FAB_NS, 'boolean' ]

    #
    # f:concat(node-set) => node
    #
    function 'concat', STRING, [ STRING ] do |ctx, args, ns|
      return '' if args.empty? || args[0].empty?
      [ args[0].collect{ |a| a.value.to_s}.join('') ]
    end

    #
    # f:string-join(node-set, joiner) => node
    #
    function 'string-join', STRING, [ STRING ] do |ctx, args, ns|
      joiner = args[1].first.value.to_s
      [ args[0].collect{|a| a.value.to_s }.join(joiner) ]
    end

    #
    # f:substring(node-set, begin)
    # f:substring(node-set, begin, length)
    #
    function 'substring', STRING, [ STRING, NUMERIC, NUMERIC ] do |ctx, args, ns|
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
    function 'string-length', NUMERIC, [ STRING ] do |ctx, args, ns|
      args[0].collect{ |a| a.to_s.length }
    end

    function 'normalize-space', STRING do |ctx, args, ns|
      args[0].collect{ |a| a.to_s.gsub(/^\s+/, '').gsub(/\s+$/,'').gsub(/\s+/, ' ') }
    end

    function 'upper-case', STRING, [ STRING ] do |ctx, args, ns|
      args[0].collect{ |a| a.to_s.upcase }
    end

    function 'lower-case', STRING, [ STRING ] do |ctx, args, ns|
      args[0].collect{ |a| a.to_s.downcase }
    end

    function 'split', STRING, [ STRING, STRING ] do |ctx, args, ns|
      div = args[1].first.to_s
      args[0].collect{ |a| a.to_s.split(div) }
    end

    function 'contains', BOOLEAN, [ STRING, STRING ] do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')
      return args[0].collect{ |a| (a.to_s.include?(tgt) rescue false) }
    end

    function 'starts-with', BOOLEAN, [ STRING, STRING ] do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')
      tgt_len = tgt.size - 1
      return args[0].collect{ |a| (a.to_s[0,tgt_len] == tgt rescue false) }
    end

    function 'ends-with', BOOLEAN, [ STRING, STRING ] do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '').reverse
      tgt_len = tgt.size
      return args[0].collect{ |a| (a.to_s[-tgt_len,-1] == tgt rescue false) }
    end

    function 'substring-before', STRING, [ STRING, STRING ] do |ctx, args, ns|
      tgt = (args[1].first.to_s rescue '')
      return [ '' ] if tgt == ''

      return args[0].collect{ |a| (a.value.to_s.split(tgt,2))[0] }
    end

    function 'substring-after', STRING, [ STRING, STRING ] do |ctx, args, ns|
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

    function 'not', BOOLEAN do |ctx, args, ns|
      return args[0].collect{ |a| !a.value }
    end

    ###
    ### data node functions
    ###

    function 'name', STRING do |ctx, args, ns|
      return args[0].collect{|a| a.name || '' }
    end

    function 'root' do |ctx, args, ns|
      return args[0].collect{|a| a.root }
    end

    function 'lang', STRING do |ctx, args, ns|
      # we want to track language for rdf purposes?
    end

    ###
    ### Sequences
    ###

    function 'empty', BOOLEAN do |ctx, args, ns|
      return [ args[0].empty? ]
    end

    function 'exists', BOOLEAN do |ctx, args, ns|
      return [ !args[0].empty? ]
    end

    function 'reverse' do |ctx, args, ns|
      return args[0].reverse
    end

    function 'zero-or-one', BOOLEAN do |ctx, args, ns|
      return [ args[0].size <= 1 ]
    end

    function 'one-or-more', BOOLEAN do |ctx, args, ns|
      return [ args[0].size >= 1 ]
    end

    function 'zero-or-one', BOOLEAN do |ctx, args, ns|
      return [ args[0].size == 1 ]
    end

    function 'count', NUMERIC do |ctx, args, ns|
      return [ args[0].size.to_d.to_r ]
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
 
    function 'uri-prefix', STRING do |ctx, args, ns|
      res = [ ]
      args[0].each do |p|
        prefix = p.to([FAB_NS, 'string']).value
        # resolve prefix to href
        res << ctx.anon_node( ns[prefix], [FAB_NS, 'string']) if ns[prefix]
      end
      res
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
