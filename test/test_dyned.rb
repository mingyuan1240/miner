#!/usr/bin/ruby
# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'dyned'

class TestDyned < Minitest::Test

  def test_compile_single_schema
    xml = <<EOF
        <schema name="root" >
          <attribute name="id" type="int32" />
          <attribute name="num" type="uint32" />
        </schema>
EOF
    shm = DynED::Schema.new(xml).compile
    source = <<EOF
:root {
attr rand32
attr randu32
}
EOF
    assert_equal source.chomp, shm.source
    assert_equal 2, shm.fill.length
  end

  def test_compile_single_schema_string_length_ref_attr
    xml = <<EOF
        <schema name="root" >
          <attribute name="len1" type="uint8" />
          <attribute name="name" type="string" length="#len1" />
          <attribute name="len2" type="uint8" />
          <attribute name="name" type="blob" length="#len2" />
        </schema>
EOF
    shm = DynED::Schema.new(xml).compile
    source = <<EOF
:root {
attr randu8
attr randstr(ref(0))
attr randu8
attr randbyte(ref(2))
}
EOF
    assert_equal source.chomp, shm.source
    tuple = shm.fill
    assert_equal 4, tuple.length
    assert_equal tuple[0], tuple[1].length
    assert_equal tuple[2], tuple[3].length
  end

  def test_compile_single_schema_lvenable
    xml = <<EOF
        <schema name="root" lvenable="true" >
          <attribute name="id" type="int32" />
          <attribute name="len" type="uint8" />
          <attribute name="name" type="string" />
          <attribute name="address" type="blob" length="10" />
          <attribute name="email" type="string" length="#len" />
        </schema>
EOF
    shm = DynED::Schema.new(xml).compile
    source = <<EOF
:root {
attr uint32 4
attr rand32
attr uint32 1
attr randu8
attr randu32 #{ Miner.random_string_len_range }
attr randstr(ref(4))
attr randu32 #{ Miner.random_string_len_range }
attr randbyte(10)
attr randu32 #{ Miner.random_string_len_range }
attr randstr(ref(3))
}
EOF
    assert_equal source.chomp, shm.source
    tuple = shm.fill
    assert_equal 10, tuple.length
  end
  
  def test_compile_single_schema_string_fix_length
    xml = <<EOF
        <schema name="root" >
          <attribute name="id" type="int32" />
          <attribute name="name" type="string" length="10" />
          <attribute name="name" type="blob" length="11" />
        </schema>
EOF
    shm = DynED::Schema.new(xml).compile
    source = <<EOF
:root {
attr rand32
attr randstr(10)
attr randbyte(11)
}
EOF
    tuple = shm.fill
    assert_equal 3, tuple.length
    assert_equal 10, tuple[1].length
    assert_equal 11, tuple[2].length
  end

  def test_choice
    choice = DynED::Choice.new 'type:Foo->Sub1,Bar->Sub2'
    assert_equal 'type', choice.attr
    assert_equal 'Sub1', choice['Foo']
    assert_equal 'Sub2', choice['Bar']
  end

  def test_choice_wrong_format
    assert_raises(DynED::FormatError) {
      DynED::Choice.new 'Foo->Sub1,Bar->Sub2'
    }

    assert_raises(DynED::FormatError) {
      DynED::Choice.new ':Foo->Sub1,Bar->Sub2'
    }

    assert_raises(DynED::FormatError) {
      DynED::Choice.new 'attr::Foo->Sub1,Bar->Sub2'
    }

    assert_raises(DynED::FormatError) {
      DynED::Choice.new 'attr:Foo->Sub1Bar->Sub2'
    }

    assert_raises(DynED::FormatError) {
      DynED::Choice.new 'attr:Foo->Sub1, Bar->Sub2'
    }
    
    assert_raises(DynED::FormatError) {
      DynED::Choice.new 'attr:Foo->Sub1,Bar->Sub2,'
    }

    assert_raises(DynED::FormatError) {
      DynED::Choice.new 'attr:Foo-Sub1Bar'
    }
  end
  
  def test_subschema
    xml = <<EOF
<root>
<enum name="Type" type="uint8" >
  <element name="Foo" value="0" />
  <element name="Bar" value="1" />
</enum>

<schema name="root" >
  <attribute name="id" type="int32" />
  <attribute name="type" type="Type" />
  <attribute name="sub" type="subschema" choice="type:Foo->Sub1,Bar->Sub2" />
</schema>

<schema name="Sub1" >
  <attribute name="value" type="int32" />
</schema>

<schema name="Sub2" >
  <attribute name="value" type="uint32" />
  <attribute name="value" type="int8" />
</schema>
</root>
EOF
    shm = DynED.load(xml).compile
    assert_equal :root, shm.name
    tuple = shm.fill
    assert_equal 3, tuple.length
  end
end
