# encoding: utf-8
# 动态编解码

require 'rexml/document'
require 'miner'

module DynED
  class FormatError < StandardError; end
  
  class << self
    def load source
      doc = REXML::Document.new source
      if doc.root.name == 'schema'
        Schema.new doc.root
      else
        enums = get_enums doc
        schemas = []
        doc.root.each_element 'schema' do |schema|
          schemas << Schema.new(schema, enums)
        end
        schemas.each &:compile
        schema_names = Set.new schemas.map(&:name)
        schemas.each do |schema|
          schema_names.subtract schema.subschemas
        end
        raise "Schema root is more then one" if schema_names.size > 1
        schemas.each do |schema|
          return schema if schema.name == schema_names.to_a.first
        end
      end
    end

    private
    def get_enums doc
      Hash[
        doc.root.get_elements('enum').map do |enum|
          [enum.attributes['name'], Enum.new(enum)]
        end
      ]
    end
  end

  class Enum < Hash
    def initialize xml
      super()

      self[:type] = xml.attributes['type'].to_sym
      self[:elements] = Hash[
        xml.elements.map do |element|
          [
            element.attributes['name'],
            element.attributes['value']
          ]
        end
      ]
    end

    def type
      self[:type]
    end

    def elements
      self[:elements]
    end

    def names
      elements.keys
    end

    def values
      elements.values.map &:to_i
    end
  end

  class Choice < Hash
    attr_reader :attr
    
    def initialize source
      super()
      
      raise FormatError, 'Illegal choice expression' unless source =~ /\A\w+:(\w+->\w+,\b)*\w+->\w+\Z/
      @attr, choices = source.split(':')
      choices.split(',').each do |choice|
        enum, schema = choice.split('->')
        self[enum] = schema
      end
    end
  end
  
  class Schema
    attr_reader :name, :lvenable, :subschemas
    
    def initialize xml, enums = nil
      if xml.kind_of? String
        xml = REXML::Document.new(xml).root
      end
      
      raise ArgumentError, "Expect schema, not #{ xml.name }" unless xml.name == 'schema'

      @xml = xml
      @name = xml.attributes['name']
      @lvenable = xml.attributes['lvenable'] == 'true'
      @enums = enums
      @subschemas = Set.new
      #      parse
    end

    def parse
      @attributes ||= {}
      @xml.elements.each do |element|
        name = element.attributes['name']
        raise "'name' attribute is necessary" unless name
        raise "Duplicate attribute: #{ name }" if @attributes[name]
        
        @attributes[length_attr_name name] = { 'type' => 'length' } if @lvenable
        @attributes[name] = element.attributes
      end
    end
    
    def length_attr_name name
      "#{ name }&len"
    end
    
    def compile
      templete = []
      names = []

      @xml.elements.each_with_index do |element, index|
        type = element.attributes['type'].to_sym
        name = element.attributes['name']
        names << name

        case type
        when :string, :blob
          templete << "attr randu32 #{ Miner.random_string_len_range }" if @lvenable
          templete << "attr #{ rand_type type }"
          length = element.attributes['length']
          if length
            if length.start_with? '#'
              ref_idx = names.index length[1..-1]
              raise "can not find ref attr: #{ length }" unless ref_idx
              if @lvenable
                templete.last << "(ref(#{ map_index(ref_idx) }))"
              else
                templete.last << "(ref(#{ ref_idx }))"
              end
            else
              templete.last << "(#{ length })"
            end
          elsif @lvenable
            templete.last << "(ref(#{ map_index(index) - 1 }))"
          end
        when :int8, :uint8, :int16, :uint16, :int32, :uint32, :int64, :uint64
          templete << "attr uint32 #{ type_len type }" if @lvenable
          templete << "attr #{ rand_type type }"
        when :subschema
          choice = Choice.new element.attributes['choice']
          templete << "case ref(#{ names.index choice.attr })"
          enum = @xml.elements[names.index(choice.attr) + 1].attributes['type']
          choice.each_pair do |value, subschema|
            templete << "when #{ @enums[enum].elements[value] } then schema(:#{ subschema })"
            subschemas << subschema
          end
          templete << 'end'
        else
          # Maybe enum
          enum_type = @enums[type.to_s].type
          templete << "attr #{ rand_enum_type(enum_type) } #{ @enums[type.to_s].values }"
        end

      end
      Miner::Schema.new @name.to_sym, templete.join("\n")
    end

    private
    # Map index which in dynamic schema to miner schema
    def map_index idx
      idx * 2 + 1
    end
    
    def type_len type
      case type
      when :uint8, :int8 then 1
      when :uint16, :int16 then 2
      when :uint32, :int32, :float, :double then 4
      when :uint64, :int64 then 8
      end
    end
    
    def rand_type type
      s = %i(int8   uint8   int16   uint16  int32   uint32  int64   uint64  string  blob)
      d = %i(rand8  randu8  rand16  randu16 rand32  randu32 rand64  randu64 randstr randbyte)
      raise TypeError, "Can not find such type: #{ type }" unless s.index type
      d[s.index type]
    end

    def rand_enum_type type
      s = %i(int8   uint8   int16   uint16  int32   uint32  int64   uint64)
      d = %i(enum8  enumu8  enum16  enumu16 enum32  enumu32 enum64  enumu64)
      raise TypeError, "Can not find such type: #{ type }" unless s.index type
      d[s.index type]
    end
  end
end
