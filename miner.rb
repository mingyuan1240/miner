#! /usr/bin/ruby
# encoding: utf-8

require 'set'
require 'base64'

class Range
  alias_method :_include?, :include?

  def include? obj
    if obj.kind_of? Range
      first <= obj.first && max >= obj.max
    else
      _include? obj
    end
  end
end

module Miner
  TOO_LONG_STRING_LENGTH = 65536
  
  class << self
    @@random_string_max_len = 128
    @@random_string_min_len = 0
    
    attr_accessor :random_string_max_len, :random_string_min_len

    def random_string_max_len
      @@random_string_max_len
    end

    def random_string_min_len
      @@random_string_min_len
    end

    def random_string_min_len= len
      raise RangeError, "Min length should not smaller then 0" if len < 0
      @@random_string_min_len = len
    end

    def random_string_max_len= len
      raise RangeError, "Warning: #{ len } is too long to slow down miner speed, if you persist, use 'random_string_max_len!'" if len > TOO_LONG_STRING_LENGTH

      random_string_max_len! len
    end

    def random_string_max_len! len
      raise RangeError, "Max length should not smaller then 0" if len < 0
      @@random_string_max_len = len
    end
    
    def random_string_len_range
      raise RangeError, "Nagetive range: #{ @@random_string_min_len..@@random_string_max_len }" if @@random_string_min_len > @@random_string_max_len
      @@random_string_min_len..@@random_string_max_len
    end
  end
  
  module Boundary
    MAX_INT8 = 2 ** 7 - 1
    MAX_UINT8 = 2 ** 8 - 1
    MIN_INT8 = -MAX_INT8 - 1

    MAX_INT16 = 2 ** 15 - 1
    MAX_UINT16 = 2 ** 16 - 1
    MIN_INT16 = -MAX_INT16 - 1

    MAX_INT32 = 2 ** 31 - 1
    MAX_UINT32 = 2 ** 32 - 1
    MIN_INT32 = -MAX_INT32 - 1

    MAX_INT64 = 2 ** 63 - 1
    MAX_UINT64 = 2 ** 64 - 1
    MIN_INT64 = -MAX_INT64 - 1
  end

  module Const
    include Boundary

    [
      [:int8, MIN_INT8..MAX_INT8],
      [:uint8, 0..MAX_UINT8],
      [:int16, MIN_INT16..MAX_INT16],
      [:uint16, 0..MAX_UINT16],
      [:int32, MIN_INT32..MAX_INT32],
      [:uint32, 0..MAX_UINT32],
      [:int64, MIN_INT64..MAX_INT64],
      [:uint64, 0..MAX_UINT64]
    ].each do |type, range|
      define_method type do |val|
        number type, val, range
      end
    end

    private
    def number(type, val, range)
      raise_range_error(type, val, range) unless range.include? val
      Attribute.new val, type
    end

    def raise_range_error(type, val, range)
      raise RangeError, "#{type} value (#{val}) is out of range: #{range}"
    end
  end

  module Random
    include Boundary

    def rand8 expect = MAX_INT8
      random :int8, (MIN_INT8..MAX_INT8), expect
    end

    def randu8 expect = MAX_UINT8
      random :uint8, (0..MAX_UINT8), expect
    end

    def rand16 expect = MAX_INT16
      random :int16, (MIN_INT16..MAX_INT16), expect
    end
    
    def randu16 expect = MAX_UINT16
      random :uint16, (0..MAX_UINT16), expect
    end
    
    def rand32 expect = MAX_INT32
      random :int32, (MIN_INT32..MAX_INT32), expect
    end

    def randu32 expect = MAX_UINT32
      random :uint32, (0..MAX_UINT32), expect
    end
    
    def rand64 expect = MAX_INT64
      random :int64, (MIN_INT64..MAX_INT64), expect
    end

    def randu64 expect = MAX_UINT64
      random :uint64, (0..MAX_UINT64), expect
    end

    def randf
      raise 'No implement'
    end

    def randd
      raise 'No implement'
    end
    
    def randstr arg = Miner.random_string_len_range
      bytes = randbyte arg
      if arg.kind_of? Fixnum
        Base64.encode64(bytes)[0, arg]
      else
        Base64.encode64(bytes)[0, min(bytes.length, arg.max)]
      end
    end

    def randbyte arg = Miner.random_string_len_range
      size = arg 
      if arg.kind_of? Range
        raise RangeError, "negative size: #{ arg }" if arg.first < 0
        size = rand arg
      end
      raise RangeError, "negative size: #{ size }" if size < 0
      Array.new((size / 8).next) { |idx| rand64.value }.pack('q*')[0...size]
    end

    private
    def random type, range, expect
      raise RangeError, "#{ expect} is out of #{ type }" unless range.include? expect
      expect = (range.first..expect) if expect.kind_of? Fixnum
      Attribute.new rand(expect), type
    end

    private
    def min a, b
      a > b ? a : b
    end
  end

  module Enum
    [
      [:enum8, :int8],
      [:enumu8, :uint8],
      [:enum16, :int16],
      [:enumu16, :uint16],
      [:enum32, :int32],
      [:enumu32, :uint32],
      [:enum64, :int64],
      [:enumu64, :uint64]
    ].each do |method, type|
      define_method method do |collection|
        enum collection, type
      end
    end

    private
    def enum collection, type
      Attribute.new collection.each.to_a.sample, type
    end
  end
  
  class Attribute
    include Comparable
    
    attr_reader :value, :type
    
    def initialize value = nil, type = nil
      if value.kind_of? Attribute
        @value = value.value
        @type = value.type
      else
        @value = value
        @type = type || case value
                        when String then :string
                        when Fixnum then :int32
                        when Float then :float
                        when Tuple then :tuple
                        when Array then :array
                        when NilClass then :nil
                        else :unknow
                        end
      end
    end

    def <=> other
      if other.kind_of? Attribute
        @value <=> other.value
      else
        @value <=> other
      end
    end

    def to_s
      @value.to_s
    end

    def to_b endian = :small
      if @type == :tuple
        @value.to_b
      else
        [@value].pack pack_type(endian)
      end
    end
    
    def inspect
      @value.inspect
    end
    
    def method_missing method, *args
      @value.send method, *args
    end

    private
    def pack_type endian
      t = %i(int8   uint8   int16   uint16  int32   uint32  int64   uint64  float   double  string)
      s = %w(c      C       s<      S<      l<      L<      q<      Q<      e       E       A)
      b = %w(c      C       s>      S>      l>      L>      q>      Q>      g       G       A)
      case endian
      when :small then s[t.index @type]
      when :big then b[t.index @type]
      end
    end
  end

  class Tuple < Array
    def to_b
      self.map(&:to_b).join
    end
  end
  
  class Schema
    include Const
    include Random
    include Enum
    
    class << self
      def [] name
        @@schemas.fetch name
      end
    end

    attr_reader :subschemas, :name
    
    def initialize name, source = nil, &block
      @name = name
      @source = source
      @templete = block
      @@schemas ||= {}
      @@schemas[name] = self
      @subschemas = Set.new
    end
    
    def fill
      @tuple = Tuple.new
      if @source
        instance_eval @source
      else
        instance_eval &@templete
      end
      @tuple
    end

    def source
      ":#{ @name } {\n#{ @source }\n}"
    end
    
    def attr a
      @tuple << Attribute.new(a)
    end

    def ref idx
      @tuple[idx].value
    end

    def schema name
      raise "Can not find such schema: #{ name }" unless Schema[name]
      raise "Can not recursive reference, schema: #{ name }" if name == @name || Schema[name].subschemas.include?(@name)
      @subschemas << name
      attr Schema[name].fill
    end

    def nullable a, probability = 0.5
      a if rand > probability
    end
  end
end
