# coding: utf-8
# AUTHOR:   s00292424
# DATE:     2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir

require 'element'
require 'base'

module Miner
    module Syntax
        module Const
            include Define
            include Base

            def int32(val)
                number 'int32', val, (MIN_INT32..MAX_INT32)
            end

            def uint32(val)
                number 'uint32', val, (0..MAX_UINT32)
            end

            def int64(val)
                number 'int64', val, (MIN_INT64..MAX_INT64)
            end

            def uint64(vl)
                number 'uint64', val, (0..MAX_UINT64)
            end

            def before(key)
                p "before in const: #{key}"
            end

            def after(key)
                p "after int const: #{ key }"
            end

            def before_int32
                p 'before int32'
            end

            register_key :int32, :int64

            private
            def number(type, val, range)
                raise_range_error(type, val, range) unless range.include? val 
                val
            end

            def raise_range_error(type, val, range)
                raise RangeError, "#{type} value (#{val}) is out of range: #{range}"
            end
        end
    end
end
