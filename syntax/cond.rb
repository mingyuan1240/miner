# coding: utf-8
# AUTHOR:   s00292424
# DATE:     2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir

require 'syntax'

module Miner
    module Syntax
        class Cond < Base
            def cond bool, yes, no
                bool ? yes : no
            end

            def switch value, cases
                cases[value] || cases[:default]
            end

            register_keyword :cond, :switch
        end
    end
end
 
