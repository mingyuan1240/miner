# coding: utf-8
# AUTHOR:   s00292424
# DATE:     2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir


require 'element'
require 'base'

module Miner
    module Syntax
        module Cond
            def cond(bool, yes, no)
                return yes if bool
                no
            end

            def switch(value, *cases)
                cases.each do |a, b|
                    return b if value == a
                end
                return @default[:default] if @default
            end

            def default(value)
                @default = { :default => value }
            end

            def before key
                p 'before in cond'
            end

            def before_int32
                p 'wrong before'
            end

            include Base
            register_key :cond, :switch
        end
    end
end
 
