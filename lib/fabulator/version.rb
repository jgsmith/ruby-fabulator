module Fabulator
  module VERSION
    unless defined? MAJOR
      MAJOR = 0
      MINOR = 0
      TINY  = 1
      PRE   = nil

      STRING = [MAJOR,MINOR,TINY].compact.join('.') + (PRE.nil? ? '' : PRE)

      SUMMARY = "rspec #{STRING}"
    end
  end
end
