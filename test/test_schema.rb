# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestSchema < Minitest::Test

  def test_base
    shm = Miner::Schema.new(:schema) {
      attr int32(0)
      attr int32(1)
    }
    assert_equal [0, 1], shm.fill
  end

  def test_randbyte
    shm = Miner::Schema.new(:root) {
      attr randbyte(0)
      attr randbyte(7)
      attr randbyte(8)
      attr randbyte
    }
    tuple = shm.fill
    assert_equal 4, tuple.length
    assert_equal 0, tuple[0].length
    assert_equal 7, tuple[1].length
    assert_equal 8, tuple[2].length
  end

  def test_randstr
    shm = Miner::Schema.new(:test) {
      attr randstr(0)
      attr randstr(7)
      attr randstr(8)
      attr randstr
    }
    tuple = shm.fill
    assert_equal 4, tuple.length
    assert_equal 0, tuple[0].length
    assert_equal 7, tuple[1].length
    assert_equal 8, tuple[2].length
  end

  def test_randstr_negative_size
    shm = Miner::Schema.new(:test) {
      attr randstr(-1)
    }
    assert_raises(ArgumentError) { shm.fill }
  end
  
  def test_load_from_xml_single_schema
    xml = <<EOF
        <schema name="root" >
          <attribute name="id" type="int32" />
          <attribute name="num" type="int32" />
        </schema>
EOF
    shm = Miner::Schema.load xml
    assert_equal 2, shm.fill.length
  end

  def test_load_from_xml_string_length
    xml = <<EOF
        <schema name="root" >
          <attribute name="id" type="int32" />
          <attribute name="name" type="string" length="10" />
          <attribute name="name" type="blob" length="11" />
        </schema>
EOF
    shm = Miner::Schema.load xml
    tuple = shm.fill
    assert_equal 3, tuple.length
    assert_equal 10, tuple[1].length
    assert_equal 11, tuple[2].length
  end

  def test_load_from_xml_string_length_ref_attr
    xml = <<EOF
        <schema name="root" >
          <attribute name="len1" type="uint8" />
          <attribute name="name" type="string" length="#len1" />
          <attribute name="len2" type="uint8" />
          <attribute name="name" type="blob" length="#len2" />
        </schema>
EOF
    shm = Miner::Schema.load xml
    tuple = shm.fill
    assert_equal 4, tuple.length
    assert_equal tuple[0], tuple[1].length
    assert_equal tuple[2], tuple[3].length
  end

      xml = <<EOF
<streamsmart name="test" type="haha" >
  <schema name="root" >
    <attribute name="id" type="int32" />
    <attribute name="type" type="Switch" />
    <attribute type="subschema" choice="type:Foo->Sub1;Bar->Sub2" />
  </schema>

  <schema name="Sub1" >
    <attribute name="name" type="string" length="10" />
  </schema>

  <schema name="Sub2" lvenable="true" >
    <attribute name="name" type="blob" />
  </schema>
</streamsmart>
EOF

end
