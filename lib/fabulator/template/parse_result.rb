require 'xml/libxml'
require 'xml/xslt'

@@fabulator_xslt_file = File.join(File.dirname(__FILE__), "..", "..", "..", "xslt", "form.xsl")

@@fabulator_xmlt = LibXML::XML::Document.file(@@fabulator_xslt_file)


module Fabulator::Template
  class ParseResult
    def initialize(text)
      @doc = LibXML::XML::Document.string text
    end

    def add_default_values(context)
      each_form_element do |el|
        own_id = el.attributes['id']
        next if own_id.nil? || own_id.to_s == ''

        default = nil
        is_grid = false
        if el.name == 'grid'
          default = el.find('./default | ./row/default | ./column/default')
          is_grid = true
        else
          default = el.find('./default')
        end

        id = el_id(el)
        ids = id.split('/')
        if !context.nil? && (default.is_a?(Array) && default.empty? || !default)
          l = context.traverse_path(ids)
          if !l.nil? && !l.empty?
            if is_grid
              count = (el.attributes['count'].to_s rescue '')
              how_many = 'multiple' 
              direction = 'both'
              if count =~ %r{^(multiple|single)(-by-(row|column))?$}
                how_many = $1
                direction = $3 || 'both'
              end
              if direction == 'both' 
                l.collect{|ll| ll.value}.each do |v|
                  el << XML::Node.new('default', v)
                end
              elsif direction == 'row' || direction == 'column'
                el.find("./#{direction}").each do |div|
                  id = (div.attributes['id'].to_s rescue '')
                  next if id == ''
                  l.collect{|c| context.with_root(c).traverse_path(id)}.flatten.collect{|c| c.value}.each do |v|
                    div << XML::Node.new('default', v)
                  end
                end
              end
            else
              l.collect{|ll| ll.value}.each do |v|
                el << XML::Node.new('default', v)
              end
            end
          end
        end
      end
    end

    def add_missing_values(missing = [ ])
      each_form_element do |el|
        id = el_id(el)
        next if id == ''
        next unless missing.include?(id)
        el.attributes["missing"] = "1"
      end
    end

    def add_errors(errors = { })
      each_form_element do |el|
        id = el_id(el)
        next if id == ''
        next unless errors.has_key?(id)
        if errors[id].is_a?(Array)
          errors[id].each do |e|
            el << XML::Node.new('error', e)
          end
        else
          el << XML::Node.new('error', errors[id])
        end
      end
    end

    def add_captions(captions = { })
      each_form_element do |el|
        id = el_id(el)
        next if id == ''
        next unless captions.has_key?(id)

        is_grid = false
        if el.name == 'grid'
        else
          caption = el.find_first('./caption')
          if caption.nil?
            el << XML::Node.new('caption', captions[id])
          else
            caption.content = captions[id]
          end
        end
      end
    end

    def to_s
      @doc.to_s
    end

    def to_html
      xslt = XML::XSLT.new
      xslt.parameters = { }
      xslt.xml = @doc
      xslt.xsl = @@fabulator_xslt
      xslt.serve
    end

protected

    def each_form_element(&block)
      @doc.root.find(%{
        //text
        | //textline
        | //textbox
        | //editbox
        | //asset
        | //password
        | //selection
        | //grid
        | //submit
      }).each do |el|
        yield el
      end
    end

    def el_id(el)
      own_id = el.attributes['id']
      return '' if own_id.nil? || own_id == ''

      ancestors = el.find(%{
        ancestor::option[@id != '']
        | ancestor::group[@id != '']
        | ancestor::form[@id != '']
        | ancestor::container[@id != '']
      })
      ids = ancestors.collect{|a| a.attributes['id']}.select{|a| !a.nil? }
      ids << own_id
      ids.collect{|i| i.to_s}.join('/')
    end
  end
end
