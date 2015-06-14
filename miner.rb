#! /usr/bin/ruby
# encoding: utf-8

require 'set'
require 'base64'
require 'rexml/document'

module Miner
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
    
    def int32 val
      number :int32, val, MIN_INT32..MAX_INT32
    end

    def uint32 val
      number :uint32, val, 0..MAX_UINT32
    end

    def int64 val
      number :int64, val, MIN_INT64..MAX_INT64
    end

    def uint64 val
      number :uint64, val, 0..MAX_UINT64
    end

    def uint8 val
      number :uint8, val, 0..MAX_UINT8
    end

    def int8 val
      number :int8, val, MIN_INT8..MAX_INT8
    end

    def int16 val
      number :int16, val, MIN_INT16..MAX_INT16
    end

    def uint16 val
      number :uint16, val, 0..MAX_UINT16
    end

    def str s
      s
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

    def rand8
      Attribute.new rand(MIN_INT8..MAX_INT8), :int8
    end

    def randu8
      Attribute.new rand(0..MAX_UINT8), :uint8
    end
    
    def rand32
      Attribute.new rand(MIN_INT32..MAX_INT32), :int32
    end

    def randu32
      Attribute.new rand(0..MAX_UINT32), :uint32
    end
    
    def randu16
      Attribute.new rand(0..MAX_UINT16), :uint16
    end

    def rand64
      Attribute.new rand(MIN_INT64..MAX_INT64), :int64
    end
    
    def randstr size = rand(MAX_UINT8)
      raise ArgumentError, "negative size: #{ size }" if size < 0
      Base64.encode64(randbyte size)[0...size]
    end

    def randbyte size = rand(MAX_UINT8)
      raise ArgumentError, "negative size: #{ size }" if size < 0
      Array.new((size / 8).next) { |idx| rand64.value }.pack('q*')[0...size]
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

    def to_b
      @type
    end
    
    def inspect
      @value.inspect
    end
    
    def method_missing method, *args
      @value.send method, *args
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

    class << self
      def [] name
        @@schemas.fetch name
      end

      def load source
        doc = REXML::Document.new source
        if doc.root.name == 'schema'
          load_schema doc.root
        end
      end
      
      private
      def load_schema xml_element
        templete = []
        names = []
        xml_element.elements.each do |element|
          attrs = element.attributes
          names << attrs['name']
          templete << "attr #{ rand_type(attrs['type']) }"
          if %w(string blob).include?(attrs['type']) && attrs['length']
            if attrs['length'].start_with? '#'
              ref_idx = names.index(attrs['length'][1..-1])
              raise "can not find ref attr: #{ attrs['length'] }" unless ref_idx
              templete.last << "(ref(#{ ref_idx }))"
            else
              templete.last << "(#{ attrs['length'] })"
            end
          end
        end
        Schema.new xml_element.attributes['name'].to_sym, templete.join("\n")
      end

      def rand_type type
        case type
        when 'uint8' then 'randu8'
        when 'int32' then 'rand32'
        when 'uint32' then 'randu32'
        when 'int64' then 'rand64'
        when 'string' then 'randstr'
        when 'blob' then 'randbyte'
        else raise TypeError, "can not find such type: #{ type }"
        end
      end
    end

    attr_reader :subschemas, :source
    
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
