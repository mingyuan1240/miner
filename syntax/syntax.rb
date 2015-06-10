# coding: utf-8
# AUTHOR: s00292424
# DATE:   2015-05-09

require 'set'

module Miner
  module Syntax
    class GrammarError < StandardError; end

    class Base
      class << self
        attr_reader :syntaxes

        def inherited klass
          @syntaxes ||= []
          @syntaxes << klass
          super
        end
        
        def clean
          @syntaxes = []
        end

        def listen
          @listen = true
        end

        def listener?
          @listen
        end

        def keywords
            @keywords.to_a 
        end

        def words
            @words.to_a
        end

        def register_keyword *kws
          kws.map(&:to_sym).each { |kw| raise NoMethodError, kw unless instance_methods.include? kw }

          @keywords ||= Set.new
          @keywords.merge kws
        end

        def register_word *wds
          wds.map(&:to_sym).each { |wd| raise NoMethodError, wd unless instance_methods.include? wd }

          @words ||= Set.new
          @words.merge wds
        end

      end
    end
    end
end
