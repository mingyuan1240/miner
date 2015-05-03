# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestMiner < Minitest::Test

    @@worker = Miner::Worker.new

    def test_tuple
        result = @@worker.work <<-EOF
        tuple { }
        EOF

        expect = [[]]

        assert_equal expect, result
    end


end
