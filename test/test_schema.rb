# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestSchema < Minitest::Test
  def test_base
    tuple = Miner::Schema.new(:schema) {
      attr int8 -8
      attr uint8 8
      attr int16 -16
      attr uint16 16
      attr int32 -32
      attr uint32 32
      attr int64 -64
      attr uint64 64
    }.fill

    assert_equal :int8, tuple[0].type
    assert_equal -8, tuple[0].value

    assert_equal :uint8, tuple[1].type
    assert_equal 8, tuple[1].value

    assert_equal :int16, tuple[2].type
    assert_equal -16, tuple[2].value

    assert_equal :uint16, tuple[3].type
    assert_equal 16, tuple[3].value
    
    assert_equal :int32, tuple[4].type
    assert_equal -32, tuple[4].value

    assert_equal :uint32, tuple[5].type
    assert_equal 32, tuple[5].value

    assert_equal :int64, tuple[6].type
    assert_equal -64, tuple[6].value

    assert_equal :uint64, tuple[7].type
    assert_equal 64, tuple[7].value
  end

  def test_rand_number
    shm = Miner::Schema.new(:test) {
      attr rand8
      attr randu8
      attr rand16
      attr randu16
      attr rand32
      attr randu32
      attr rand64
      attr randu64
    }
    tuple = shm.fill
    assert_equal 8, tuple.length
    assert_equal :int8, tuple[0].type
    assert_includes (Miner::Schema::MIN_INT8..Miner::Schema::MAX_INT8), tuple[0].value
    assert_equal :uint8, tuple[1].type
    assert_includes (0..Miner::Schema::MAX_UINT8), tuple[1].value

    assert_equal :int16, tuple[2].type
    assert_includes (Miner::Schema::MIN_INT16..Miner::Schema::MAX_INT16), tuple[2].value
    assert_equal :uint16, tuple[3].type
    assert_includes (0..Miner::Schema::MAX_UINT16), tuple[3].value

    assert_equal :int32, tuple[4].type
    assert_includes (Miner::Schema::MIN_INT32..Miner::Schema::MAX_INT32), tuple[4].value
    assert_equal :uint32, tuple[5].type
    assert_includes (0..Miner::Schema::MAX_UINT32), tuple[5].value

    assert_equal :int64, tuple[6].type
    assert_includes (Miner::Schema::MIN_INT64..Miner::Schema::MAX_INT64), tuple[6].value
    assert_equal :uint64, tuple[7].type
    assert_includes (0..Miner::Schema::MAX_UINT64), tuple[7].value
  end

  def test_rand_explicit_max
    shm = Miner::Schema.new(:test) {
      attr rand8 8
      attr randu8 8
      attr rand16 8
      attr randu16 8
      attr rand32 8
      attr randu32 8
      attr rand64 8
      attr randu64 8
    }
    tuple = shm.fill
    assert_equal 8, tuple.length
    assert_includes (Miner::Schema::MIN_INT8..8), tuple[0].value
    assert_includes (0..8), tuple[1].value

    assert_includes (Miner::Schema::MIN_INT16..8), tuple[2].value
    assert_includes (0..8), tuple[3].value

    assert_includes (Miner::Schema::MIN_INT32..8), tuple[4].value
    assert_includes (0..8), tuple[5].value

    assert_includes (Miner::Schema::MIN_INT64..8), tuple[6].value
    assert_includes (0..8), tuple[7].value
  end

  def test_rand_explicit_max_outof_range
    shm = Miner::Schema.new(:test) {
      attr rand8 (Miner::Schema::MAX_INT8 + 1)
    }

    assert_raises(RangeError) { shm.fill }
  end

  def test_rand_explicit_range
    shm = Miner::Schema.new(:test) {
      attr rand8 (1..8)
      attr randu8 (1..8)
      attr rand16 (1..8)
      attr randu16 (1..8)
      attr rand32 (1..8)
      attr randu32 (1..8)
      attr rand64 (1..8)
      attr randu64 (1..8)
    }
    tuple = shm.fill
    assert_equal 8, tuple.length
    assert_includes (1..8), tuple[0].value
    assert_includes (1..8), tuple[1].value
    assert_includes (1..8), tuple[2].value
    assert_includes (1..8), tuple[3].value
    assert_includes (1..8), tuple[4].value
    assert_includes (1..8), tuple[5].value
    assert_includes (1..8), tuple[6].value
    assert_includes (1..8), tuple[7].value
  end

  def test_rand_explicit_range_outof_range
    assert_raises(RangeError) {
      Miner::Schema.new(:test) {
        attr rand8 (Miner::Schema::MIN_INT8 - 1..0)
      }.fill
    }

    assert_raises(RangeError) {
      Miner::Schema.new(:test) {
        attr randu8 (0..Miner::Schema::MAX_UINT8 + 1)
      }.fill
    }
  end
  
  def test_randbyte
    shm = Miner::Schema.new(:root) {
      attr randbyte(0)
      attr randbyte(7)
      attr randbyte(8)
      attr randbyte
      attr randbyte 0..10
    }
    tuple = shm.fill
    assert_equal 5, tuple.length
    assert_equal 0, tuple[0].length
    assert_equal 7, tuple[1].length
    assert_equal 8, tuple[2].length
    assert_includes Miner.random_string_len_range, tuple[3].length
    assert_includes 0..10, tuple[4].length
  end

  def test_randstr
    shm = Miner::Schema.new(:test) {
      attr randstr(0)
      attr randstr(7)
      attr randstr(8)
      attr randstr
      attr randstr 0..10
    }
    tuple = shm.fill
    assert_equal 5, tuple.length
    assert_equal 0, tuple[0].length
    assert_equal 7, tuple[1].length
    assert_equal 8, tuple[2].length
    assert_includes Miner.random_string_len_range, tuple[3].length
    assert_includes 0..10, tuple[4].length
  end

  def test_randstr_negative_size
    assert_raises(RangeError) {
      Miner::Schema.new(:test) {
        attr randstr(-1)
      }.fill
    }

    assert_raises(RangeError) {
      Miner::Schema.new(:test) {
        attr randstr -1..2
      }.fill
    }
  end

  def test_enum
    tuple = Miner::Schema.new(:test) {
      attr enum8 [0, 1]
      attr enumu8 0..1
      attr enum16 [0, 1]
      attr enumu16 0..1
      attr enum32 [0, 1]
      attr enumu32 0..1
      attr enum64 [0, 1]
      attr enumu64 0..1
    }.fill

    assert_equal :int8, tuple[0].type
    assert_includes [0, 1], tuple[0].value

    assert_equal :uint8, tuple[1].type
    assert_includes 0..1, tuple[1].value

    assert_equal :int16, tuple[2].type
    assert_includes 0..1, tuple[2].value

    assert_equal :uint16, tuple[3].type
    assert_includes 0..1, tuple[3].value

    assert_equal :int32, tuple[4].type
    assert_includes 0..1, tuple[4].value

    assert_equal :uint32, tuple[5].type
    assert_includes 0..1, tuple[5].value

    assert_equal :int64, tuple[6].type
    assert_includes 0..1, tuple[6].value

    assert_equal :uint64, tuple[7].type
    assert_includes 0..1, tuple[7].value
  end
  
end
