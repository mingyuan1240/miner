# coding: utf-8
# AUTHOR:   s00292424
# DATE:     2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir

require 'syntax'

module Miner
    module Syntax
        module Random
            def rand32(max=100)
                "rand32"
            end

            def rand64(max)
                'rand64'
            end
        end
    end
end
