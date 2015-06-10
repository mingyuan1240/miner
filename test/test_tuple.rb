# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestTuple < Minitest::Test
    @@worker = Miner::Worker.new

    def test_tuple
        script = <<-EOF
            tuple { int32(1); int32(1) }
        EOF
        result = @@worker.work script
        expect = [1, 1]
        assert_equal expect, result
    end

    def test_empty_tuple
        script = <<-EOF
            tuple { }
        EOF
        result = @@worker.work script
        expect = []
        assert_equal expect, result
    end

    def test_mult_tuple
        script = <<-EOF
            tuple { i(1); i(2); i(3) }
            tuple { i(1); i(2); i(3) }
        EOF
        result = @@worker.work script
        expect = [
            [1, 2, 3],
            [1, 2, 3]
        ]
        assert_equal expect, result
    end

    def test_nest_tuple
        script = <<-EOF
            tuple { i(1); tuple { i(2); tuple { i(3) }; tuple { tuple { i(4) } } } }
        EOF
        result = @@worker.work script
        expect = [1, [2, [3], [[4]]]]
        assert_equal expect, result
    end

    def test_same
        script = <<-EOF
            tuple { i(1); same(0) }
        EOF
        result = @@worker.work script
        expect = [1, 1]
        assert_equal expect, result
    end

    def test_ref
        script = <<-EOF
            tuple { i(1); ref(0) }
        EOF
        result = @@worker.work script
        expect = [1]
        assert_equal expect, result
    end

    def test_ref_out_of_index
        script = <<-EOF
            tuple { ref(1) }
        EOF
        assert_raises IndexError do
            @@worker.work script
        end
    end

    def test_same_ref
        script = <<-EOF
            tuple { i(1); i(2); same(ref(0)) }
        EOF
        result = @@worker.work script
        expect = [1, 2, 2]
        assert_equal expect, result
    end

end


