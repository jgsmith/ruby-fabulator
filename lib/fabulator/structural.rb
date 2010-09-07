module Fabulator
  class Structural < Action

    def compile_xml(xml, context)
      XML.default_line_numbers = true
      if xml.is_a?(String)
        xml = LibXML::XML::Document.string xml
      end
      if xml.is_a?(LibXML::XML::Document)
        xml = xml.root
      end

      if context.nil?
        @context = @context.merge(xml)
      else
        @context = context.merge(xml)
      end

      self.setup(xml)

      self
    end

    def self.element(nom)
      @@elements[self.name] = nom
    end

    def self.contains(nom, opts = { })
      ns = opts[:ns] || self.namespace
      @@structurals ||= { }
      @@structurals[self.name] ||= { }
      @@structurals[self.name][ns] ||= { }
      @@structurals[self.name][ns][nom.to_sym] = opts
    end

    def self.structurals
      return @@structurals[self.name]
    end

    def self.accepts_structural?(ns, nom)
      return false if @@structurals.nil?
      return false if @@structurals[self.name].nil?
      return false if @@structurals[self.name][ns].nil?
      return false if @@structurals[self.name][ns][nom.to_sym].nil?
      return true
    end

    def accepts_structural?(ns, nom)
      self.class.accepts_structural?(ns, nom)
    end


  protected
    def setup(xml)
      super

      #klass = self.class.name
      possibilities = self.class.structurals

      if !possibilities.nil?
        possibilities.each_pair do |ns, parts|
          parts.each_pair do |nom, opts|
            as = "@" + (opts[:as] || nom.to_s.pluralize).to_s
            if opts[:storage].nil? || opts[:storage] == :array
              self.instance_variable_set(as.to_sym, [])
            elsif opts[:storage] == :hash
              self.instance_variable_set(as.to_sym, {})
            end
          end
        end

        structs = @context.compile_structurals(xml)
        structs.each_pair do |ns, parts|
          next unless possibilities[ns]
          parts.each_pair do |nom, objs|
            next unless possibilities[ns][nom]
            opts = possibilities[ns][nom]
            as = "@" + (opts[:as] || nom.to_s.pluralize).to_s
            if opts[:storage].nil? || opts[:storage] == :array
              self.instance_variable_set(as.to_sym, self.instance_variable_get(as.to_sym) + objs)
            else
              tgt = self.instance_variable_get(as.to_sym)
              objs.each do |obj|
                tgt[obj.send(opts[:key] || :name)] = obj
              end
            end
          end
        end
      end
    end
  end
end
