# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestMiner < Minitest::Test
  def teardown
    Miner.random_string_min_len = 0
    Miner.random_string_max_len = 128
  end
  
  def test_set_random_string_min_len
    Miner.random_string_min_len = 1
    Miner.random_string_max_len = 10
    assert_equal 1, Miner.random_string_min_len
    assert_equal 10, Miner.random_string_max_len
    assert_equal 1..10, Miner.random_string_len_range

    assert_raises(RangeError) {
      Miner.random_string_min_len = -1
    }

    assert_raises(RangeError) {
      Miner.random_string_max_len = -1
    }
  end

  def test_raise_if_max_len_smaller_then_min_len
    Miner.random_string_min_len = 10
    Miner.random_string_max_len = 5

    assert_raises(RangeError) {
      Miner.random_string_len_range
    }
  end
  
  def test_forbid_too_big_random_string_max_len
    before = Miner.random_string_max_len
    assert_raises(RangeError) {
      Miner.random_string_max_len = Miner::TOO_LONG_STRING_LENGTH + 1
    }
    assert_equal before, Miner.random_string_max_len
  end

  def test_set_random_string_max_len_bang_method
    Miner.random_string_max_len! Miner::TOO_LONG_STRING_LENGTH + 1
    assert_equal Miner::TOO_LONG_STRING_LENGTH + 1, Miner.random_string_max_len
  end
end
