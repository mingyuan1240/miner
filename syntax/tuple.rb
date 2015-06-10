# coding: utf-8
# AUTHOR: s00292424
# DATE:   2015-04-18

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir

require 'syntax'

module Miner
  module Syntax
    class Tuple < Base
      include Miner::Listener

      def tuple
        yield
        @tuple
      end

      def ref idx
        raise IndexError, "ref: #{ idx }" if idx < 0 || idx >= @tuple.length
        @tuple[idx]
      end

      alias_method :same, :ref

      register_keyword :tuple, :same
      register_word :ref
      listen

      def before_tuple
        @tuple_stack ||= []
        @tuple = []
        @tuple_stack << @tuple
      end

      def after_tuple result
        @tuple_stack.pop
        unless @tuple_stack.empty?
          @tuple_stack.last << @tuple
          @tuple = @tuple_stack.last
        end
      end

      def after_keyword keyword, result
        @tuple << result unless keyword == :tuple
      end

      end
  end
end
