module Fabulator::Expr::TagLib
  mattr_accessor :last_description, :element_descriptions, :element_options, :namespaces

  @@element_descriptions = { }
  @@element_options = { }
  @@namespaces = { }

  def self.included(base)
    base.extend(ClassMethods)
  end

  def parse_tag(name, xml)
    send "element:#{name}", xml
  end

  def element_descriptions(hash = nil)
    self.class.element_descriptions hash
  end

  def element_options(hash = nil)
    self.class.element_options hash
  end

  module ClassMethods
    def element_descriptions(hash = nil)
      Fabulator::Expr::TagLib.element_descriptions[self.name] ||= (hash || {})
    end

    def element_options(hash = nil)
      Fabulator::Expr::TagLib.element_options[self.name] ||= (hash || {})
    end

    def namespace(ns)
      Fabulator::Expr::TagLib.namespaces[ns] = self
    end

    def desc(text)
      Fabulator::Expr::TagLib.last_description = RedCloth.new(Util.strip_leading_whitespace(text)).to_html
    end

    def element(name, options = {}, &block)
      self.element_descriptions[name] = Fabulator::Expr::TagLib.last_description if Fabulator::Expr::TagLib.last_description
      Fabulator::Expr::TagLib.last_description = nil
      self.element_options[name] = options
      define_method("element:#{name}", &block)
    end
  end

  module Util
    def self.strip_leading_whitespace(text)
      Radiant::Taggable::Util.strip_leading_whitespace(text)
    end

    def self.elements_in_array(array)
      array.grep(/^element:/).map { |name| name[8..-1] }.sort
    end
  end
end

module Fabulator
  module Expr
    class StandardLib
      include Fabulator::Expr::TagLib

      namespace 'http://dh.tamu.edu/ns/xsm/1.0#'

      desc %{
        root element for applications
      }
      element 'application' do |xml|
        Fabulator::Expr::StateMachine.new(xml)
      end

      desc %{
        container for view information
      }
      element 'view' do |xml|
        Fabulator::Expr::State.new(xml)
      end
    end
  end
end
