# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestMiner < Minitest::Test
  @@worker = Miner::Worker.new
  
  def test_load
  end
end
