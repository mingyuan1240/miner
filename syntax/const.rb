# coding: utf-8
# AUTHOR:   s00292424
# DATE:     2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir

require 'syntax'

module Miner
    module Syntax
        class Const < Base
            include Miner::Define

            def int32 val
                number 'int32', val, MIN_INT32..MAX_INT32
            end

            def uint32 val
                number 'uint32', val, 0..MAX_UINT32
            end

            def int64 val
                number 'int64', val, MIN_INT64..MAX_INT64
            end

            def uint64 val
                number 'uint64', val, 0..MAX_UINT64
            end

            def uint8 val
                number 'uint8', val, 0..MAX_UINT8
            end

            def int8 val
                number 'int8', val, MIN_INT8..MAX_INT8
            end

            def int16 val
                number 'int16', val, MIN_INT16..MAX_INT16
            end

            def uint16 val
                number 'uint16', val, 0..MAX_UINT16
            end

            def i val
                val.to_i
            end

            register_keyword :int8, :uint8, :int16, :uint16, :int32, :uint32, :int64, :uint64, :i

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
