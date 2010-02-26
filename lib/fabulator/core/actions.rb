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
      :converts => [
        { :type => [ FAB_NS, 'string' ],
          :weight => 1.0,
          :convert => Proc.new { |i| i ? 'true' : '' }
        },
        { :type => [ FAB_NS, 'numeric' ],
          :weight => 1.0,
          :convert => Proc.new{ |i| Rational.new(i ? 1 : 0, 1) }
        },
      ]
    }

    register_type 'string', {
      :ops => {
        :plus => { 
        },
        :minus => { 
          :proc => Proc.new { |a,b| a.split(b).join('')} 
        },
        :mpy => {
          :args => [ [ FAB_NS, 'string' ], [ FAB_NS, 'integer' ] ],
          :proc => Proc.new { |a,b| a * b }
        },
        :lt => { },
        :eq => { },
      },
      :converts => [
        { :type => [ FAB_NS, 'boolean' ],
          :weight => 0.0001,
          :convert => Proc.new { |s| !(s.nil? || s == '' || s =~ /\s*/) }
        },
      ],
    }

    register_type 'numeric', {
      :ops => {
        :plus => { },
        :minus => { },
        :mpy => { },
        :div => { },
        :mod => { },
        :lt => { },
        :eq => { },
      },
      :converts => [
        { :type => [ FAB_NS, 'string' ],
          :weight => 1.0,
          :convert => Proc.new { |n| n.to_s }
        },
        { :type => [ FAB_NS, 'boolean' ],
          :weight => 0.0001,
          :convert => Proc.new { |n| n != 0 }
        },
      ],
    }


    ###
    ### Numeric functions
    ###

    NUMERIC = [ FAB_NS, 'numeric' ]

    function 'abs', NUMERIC, [ NUMERIC ] do |ctx, args|
      res = [ ]
      args[0].each do |i|
        res << i.value.abs
      end
      res.collect { |i| i % 1 == 0 ? i.to_i : i }
    end

    function 'ceiling', NUMERIC, [ NUMERIC ] do |ctx, args|
      res = [ ]
      args[0].each do |i|
        res << i.value.to_d.ceil.to_r
      end
      res
    end

    function 'floor', NUMERIC, [ NUMERIC ] do |ctx, args|
      res = [ ]
      args[0].each do |i|
        res << i.value.to_d.floor.to_r
      end
      res
    end

    function 'sum', NUMERIC, [ NUMERIC ] do |ctx, args|
      res = 0
      return [ res ] if args.empty?
      return args[1] if args[0].empty? && args.size > 1

      args[0].each do |a|
        #puts "adding #{YAML::dump(a)}"
        res = res + a.value
      end
      [ res ]
    end

    function 'avg', NUMERIC, [ NUMERIC ] do |ctx, args|
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

    function 'max', NUMERIC, [ NUMERIC ] do |ctx, args|
      res = nil
      args[0].each do |a|
        res = a.value.to_f if res.nil? || a.value.to_f > res
      end

      if res.floor == res
        [res.to_i]
      else
        [res]
      end
    end

    function 'min', NUMERIC, [ NUMERIC ] do |ctx, args|
      res = nil
      args[0].each do |a|
        res = a.value.to_f if res.nil? || a.value.to_f < res
      end

      if res.floor == res
        [res.to_i]
      else
        [res]
      end
    end

    function 'histogram', NUMERIC, [ NUMERIC ] do |ctx, args|
      acc = { }
      args[0].each do |a|
        acc[a.value.to_s] ||= 0
        acc[a.value.to_s] = acc[a.value.to_s] + 1
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
    function 'concat', STRING, [ STRING ] do |ctx, args|
      return '' if args.empty? || args[0].empty?
      [ args[0].collect{ |a| a.value.to_s}.join('') ]
    end

    #
    # f:string-join(node-set, joiner) => node
    #
    function 'string-join', STRING, [ STRING ] do |ctx, args|
      joiner = args[1].first.value.to_s
      [ args[0].collect{|a| a.value.to_s }.join(joiner) ]
    end

    #
    # f:substring(node-set, begin)
    # f:substring(node-set, begin, length)
    #
    function 'substring', STRING, [ STRING, NUMERIC, NUMERIC ] do |ctx, args|
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
    function 'string-length', STRING, [ STRING ] do |ctx, args|
      args[0].collect{ |a| a.value.to_s.length }
    end

    function 'normalize-space' do |ctx, args|
      args[0].collect{ |a| a.value.to_s.gsub(/^\s+/, '').gsub(/\s+$/,'').gsub(/\s+/, ' ') }
    end

    function 'upper-case', STRING, [ STRING ] do |ctx, args|
      args[0].collect{ |a| a.value.to_s.upcase }
    end

    function 'lower-case', STRING, [ STRING ] do |ctx, args|
      args[0].collect{ |a| a.value.to_s.downcase }
    end

    function 'split', STRING, [ STRING, STRING ] do |ctx, args|
      div = args[1].first.value
      args[0].collect{ |a| a.value.split(div) }
    end

    function 'contains', BOOLEAN, [ STRING, STRING ] do |ctx, args|
      tgt = (args[1].first.value.to_s rescue '')
      return args[0].collect{ |a| (a.value.to_s.include?(tgt) rescue false) }
    end

    function 'starts-with', BOOLEAN, [ STRING, STRING ] do |ctx, args|
      tgt = (args[1].first.value.to_s rescue '')
      tgt_len = tgt.size - 1
      return args[0].collect{ |a| (a.value.to_s[0,tgt_len] == tgt rescue false) }
    end

    function 'ends-with', BOOLEAN, [ STRING, STRING ] do |ctx, args|
      tgt = (args[1].first.value.to_s rescue '').reverse
      tgt_len = tgt.size
      return args[0].collect{ |a| (a.value.to_s[-tgt_len,-1] == tgt rescue false) }
    end

    function 'substring-before', STRING, [ STRING, STRING ] do |ctx, args|
      tgt = (args[1].first.value.to_s rescue '')
      return [ '' ] if tgt == ''

      return args[0].collect{ |a| (a.value.to_s.split(tgt,2))[0] }
    end

    function 'substring-after', STRING, [ STRING, STRING ] do |ctx, args|
      tgt = (args[1].first.value.to_s rescue '')

      return args[0].collect{ |a| a.value.to_s } if tgt == ''

      return args[0].collect{ |a| a.value.to_s.include?(tgt) ? (a.value.to_s.split(tgt))[-1] : "" }
    end
    

    ###
    ### Regexes
    ###

    function 'matches' do |ctx, args|
    end

    function 'replace' do |ctx, args|
    end

    function 'tokenize' do |ctx, args|
    end

    ###
    ### Boolean
    ###

    function 'true' do |ctx, args|
      return [ ctx.anon_node( true, [ FAB_NS, 'boolean' ] ) ]
    end

    function 'false' do |ctx, args|
      return [ ctx.anon_node( false, [ FAB_NS, 'boolean' ] ) ]
    end

    function 'not' do |ctx, args|
      return args[0].collect{ |a| !a.value }
    end

    ###
    ### data node functions
    ###

    function 'name' do |ctx, args|
      return args[0].collect{|a| a.name || '' }
    end

    function 'root' do |ctx, args|
      return args[0].collect{|a| a.root }
    end

    function 'lang' do |ctx, args|
      # we want to track language for rdf purposes?
    end

    ###
    ### Sequences
    ###

    function 'empty' do |ctx, args|
      return [ args[0].empty? ]
    end

    function 'exists' do |ctx, args|
      return [ !args[0].empty? ]
    end

    function 'reverse' do |ctx, args|
      return args[0].reverse
    end

    function 'zero-or-one' do |ctx, args|
      return [ args[0].size <= 1 ]
    end

    function 'one-or-more' do |ctx, args|
      return [ args[0].size >= 1 ]
    end

    function 'zero-or-one' do |ctx, args|
      return [ args[0].size == 1 ]
    end

    function 'count' do |ctx, args|
      return [ args[0].size ]
    end

    ###
    ### Context
    ###

    function 'position' do |ctx, args|
    end

    function 'last' do |ctx, args|
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
