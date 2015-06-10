# encoding: utf-8

require 'minitest/autorun'
require './base'
require 'miner'

class TestSyntaxBase < MiniTest::Test

    def setup
        @base = Miner::Syntax::Base
        @base.clean
    end

    def test_inherited_by_syntax
        syntax1 = Class.new @base
        syntax2 = Class.new @base
        assert_equal [syntax1, syntax2], @base.syntaxes
    end

    def test_clean_syntax
        syntax1 = Class.new @base
        syntax2 = Class.new @base
        @base.clean
        assert_empty @base.syntaxes
    end

    def test_can_not_register_no_method
        syntax = Class.new @base
        assert_raises NoMethodError do
            syntax.register_keyword :keyword
        end
    end

    def test_register
        syntax = Class.new @base
        syntax.class_eval do
            def key1; end
            def key2; end
            def key3; end
        end
        syntax.register_keyword :key1
        syntax.register_keyword :key1, :key2
        syntax.register_keyword :key1, :key2, :key3

        assert_equal [:key1, :key2, :key3], syntax.keywords
    end

end
