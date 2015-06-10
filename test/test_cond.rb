# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestCond < Minitest::Test
    @@worker = Miner::Worker.new

    def test_cond_yes
        script = <<-EOF
            tuple { cond(2 > 1, :yes, :no) }
        EOF
        result = @@worker.work script
        expect = [:yes]
        assert_equal expect, result
    end

    def test_cond_no
        script = <<-EOF
            tuple { cond(2 < 1, :yes, :no) }
        EOF
        result = @@worker.work script
        expect = [:no]
        assert_equal expect, result
    end

    def test_cond_ref
        script = <<-EOF
            tuple { i(1); i(2); cond(ref(0) < ref(1), ref(0), ref(1)) }
        EOF
        result = @@worker.work script
        expect = [1, 2, 1]
        assert_equal expect, result
    end

    def test_switch
        script = <<-EOF
            tuple { i(1); switch(ref(0), 0 => :zero, 1 => :one) }
        EOF
        result = @@worker.work script
        expect = [1, :one]
        assert_equal expect, result
    end
    
    def test_switch_default
        script = <<-EOF
            tuple { i(3); switch(ref(0), 0 => :zero, 1 => :one, :default => :null) }
        EOF
        result = @@worker.work script
        expect = [3, :null]
        assert_equal expect, result
    end



end 
