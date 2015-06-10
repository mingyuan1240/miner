# encoding: utf-8

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
    
    def rand32
      Attribute.new rand(MIN_INT32..MAX_INT32), :int32
    end
    
  end

  class Attribute
    class << self
      include Const
    end

    include Comparable
    
    attr_reader :value, :type
    
    def initialize value = nil, type = nil
      @value = value
      @type = type || case value
                      when String then :string
                      when Fixnum then :int32
                      when Float then :float
                      when Array then :array
                      when NilClass then :nil
                      else :unknow
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

    def inspect
      @value.inspect
    end
    
    def method_missing method, *args
      @value.send method, *args
    end
  end

  class Tuple < Array
    def nullable probability = 0.5
      if probability >= rand
        self[-1] = Attribute.new
      end      
    end

    def to_b
    end
  end


  class Schema
    class << self
      alias_method :origin_include, :include

      def include mod
        origin_include mod
        mod.public_instance_methods.each do |method|
          alias_method "_#{ method }", method
          define_method method do |*args|
            new_attr send("_#{ method }", *args)
          end
        end
      end
    end
    
    include Const
    include Random
    
    def self.[] name
      @@schemas.fetch name
    end
    
    def initialize name, &block
      @name = name
      @templete = block
      @@schemas ||= {}
      @@schemas[name] = self
    end

    def fill
      @tuple = Tuple.new
      self.instance_eval &@templete
      @tuple
    end
    
    def new_attr attr
      @tuple << attr
    end

    def ref idx
      @tuple[idx]
    end

    def copy idx
      new_attr ref(idx)
    end
    
    def schema name
      raise "Can not recursive reference, schema: #{ name }" if name == @name
      new_attr Schema[name].fill
    end

    # HACK: It's not very elegant
    def nullable attr, probability = 0.5
      @tuple[-1] = nil if rand < probability
    end
  end
end

shm = Miner::Schema.new(:student) {
  int32(2)
  nullable(rand32, 0.6)
  int32(1)
  copy(1)
  ref(0) < ref(1) ? copy(1) : copy(0)
  case ref(1)
  when 0 then str('zero')
  when 1 then str('one')
  end
}

Miner::Schema.new(:sub1) {
  int32 10
  str 'abc'
}

fin = Miner::Schema.new(:final) {
  int32(2)
  rand32
  ref(1).even? ? schema(:student) : schema(:sub1)
}

p fin.fill

