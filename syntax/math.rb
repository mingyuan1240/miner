# coding: utf-8
# AUTHOR:   s00292424
# DATE:     2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir


require 'element'
require 'base'

module Miner
    module Syntax
        module Math
            def add(a, b)
                a + b
            end

            include Base
            register_key :add
        end
    end
end
