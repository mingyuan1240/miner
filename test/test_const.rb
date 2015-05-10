# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestConst < Minitest::Test

    @@worker = Miner::Worker.new

    def test_const_int32
        script = <<-EOF
        tuple { int32(-1); int32(-(2 ** 31)); int32(2 ** 31 - 1) }
        EOF

        result = @@worker.work script
        expect = [-1, -(2 ** 31), 2 ** 31 - 1]

        assert_equal expect, result
    end

    def test_const_int32_smaller
        assert_raises RangeError do
            @@worker.work <<-EOF
                tuple { int32(-(2 ** 31) - 1) }
            EOF
        end
    end

    def test_const_int32_bigger
        assert_raises RangeError do
            @@worker.work <<-EOF
                tuple { int32(2 ** 31) }
            EOF
        end
    end

    def test_const_uint32
        script = <<-EOF
        tuple { uint32(0); uint32(2 ** 32 - 1) }
        EOF
        result = @@worker.work script
        expect = [0, 2 ** 32 - 1]
        assert_equal expect, result
    end

    def test_const_uint32_smaller
        assert_raises RangeError do
            @@worker.work <<-EOF
                tuple { uint32(-1) }
            EOF
        end
    end
    
    def test_const_uint32_bigger
        assert_raises RangeError do
            @@worker.work <<-EOF
                tuple { uint32(2 ** 32) }
            EOF
        end
    end

end
