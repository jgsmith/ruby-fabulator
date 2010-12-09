#! /usr/local/bin/ruby

require 'fabulator'
require 'fabulator/template'

version = ">= 0"

gem 'cucumber', version
load Gem.bin_path('cucumber', 'cucumber', version)

