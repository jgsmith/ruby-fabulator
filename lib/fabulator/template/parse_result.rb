require 'xml/libxml'
require 'libxslt'

module Fabulator::Template
  class ParseResult

    @@fabulator_xslt_file = File.join(File.dirname(__FILE__), "..", "..", "..", "xslt", "form.xsl")


    @@fabulator_xslt_doc = LibXML::XML::Document.file(@@fabulator_xslt_file)
    @@fabulator_xslt = LibXSLT::XSLT::Stylesheet.new(@@fabulator_xslt_doc)


    def initialize(text)
      @doc = LibXML::XML::Document.string text
    end

    def add_default_values(context)
      return if context.nil?
      each_form_element do |el|
        own_id = el.attributes['id']
        next if own_id.nil? || own_id.to_s == ''

        default = nil
        is_grid = false
        if el.name == 'grid'
          default = el.find('./default | ./row/default | ./column/default').to_a
          is_grid = true
        else
          default = el.find('./default').to_a
        end

        id = el_id(el)
        ids = id.split('/')
        l = context.traverse_path(ids)
        if !l.nil? && !l.empty?
          if !default.nil? && !default.empty?
            default.each { |d| d.remove! }
          end
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
                el << text_node('default', v)
              end
            elsif direction == 'row' || direction == 'column'
              el.find("./#{direction}").each do |div|
                id = (div.attributes['id'].to_s rescue '')
                next if id == ''
                l.collect{|c| context.with_root(c).traverse_path(id)}.flatten.collect{|c| c.value}.each do |v|
                  div << text_node('default', v)
                end
              end
            end
          else
            l.collect{|ll| ll.value}.each do |v|
              el << text_node('default', v)
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
            el << text_node('error', e) 
          end
        else
          el << text_node('error', errors[id])
        end
      end
    end

    def add_captions(captions = { })
      each_form_element do |el|
        id = el_id(el)
        next if id == ''
        caption = nil
        if captions.is_a?(Hash)
          caption = captions[id]
        else
          caption = captions.traverse_path(id.split('.')).first.to_s
        end

        next if caption.nil?

        is_grid = false
        if el.name == 'grid'
        else
          cap = el.find_first('./caption')
          if cap.nil?
            el << text_node('caption', caption)
          else
            cap.content = caption
            cap.parent << text_node('caption', caption)
            cap.remove!
          end
        end
      end
    end

    def to_s
      @doc.to_s
    end

    def to_html(popts = { })
      opts = { :form => true }.update(popts)

      res = @@fabulator_xslt.apply(@doc)

      if opts[:form]
        res.to_s
      else
        res.find('//form/*').collect{ |e| e.to_s}.join('')
      end
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

    def text_node(n,t)
      e = XML::Node.new(n)
      e << t
      e
    end
  end
end
