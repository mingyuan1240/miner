# encoding: utf-8

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir
#$: << current_dir + "/main" unless $:.include? current_dir + "/main"

#require 'element'
#require 'syntax/random'
#require 'syntax/cond'
#require 'syntax/math'
#require 'syntax/base'

module Miner
  class DuplicateKeywordError < StandardError; end
  class DuplicateWordError < StandardError; end

  module Define
    MAX_INT8 = 2 ** 7 - 1
    MAX_UINT8 = 2 ** 8 - 1
    MIN_INT8 = -MAX_INT8 - 1

    MAX_INT16 = 2 ** 15 - 1
    MAX_UINT16 = 2 ** 16 - 1
    MIN_INT16 = -MAX_INT16 - 1

    MAX_INT32 = 2 ** 31 - 1
    MAX_UINT32 = 2 ** 32 - 1
    MIN_INT32 = -MAX_INT32 - 1

    MAX_INT64 = 2 ** 63 - 1
    MAX_UINT64 = 2 ** 64 - 1
    MIN_INT64 = -MAX_INT64 - 1
  end

  module Listener
    def before_keyword keyword; end
    def after_keyword keyword, result; end

    #def yielded , keyword, result; end

    def before_word word; end
    def after_word word, result; end
  end

  #require 'syntax/tuple'
  require 'syntax/const'
  require 'syntax/cond'

  class Worker 
    attr_accessor :appender
    def initialize
      @appender = self
      @kw_dispatcher = {}
      @wd_dispatcher = {}
      @listeners = []
      Syntax::Base.syntaxes.each do |syntax|
        s = syntax.new
        syntax.keywords.each do |kw|
          if @kw_dispatcher[kw]
            clean
            raise DuplicateKeywordError, kw 
          end
          @kw_dispatcher[kw] = s
        end

        syntax.words.each do |wd|
          if @wd_dispatcher[wd]
            clean
            raise DuplicateWordError, wd
          end
          @wd_dispatcher[wd] = s
        end
        @listeners << s if syntax.listener?
      end
    end

    def self.work script
      Worker.new.work script 
    end

    def work script
      instance_eval script
    end

    def repeat times 
      unless @repeat_root
        @repeat = @repeat_root = Repeat.new times
      else
        new_repeat = Repeat.new times
        @repeat << new_repeat
        @repeat = new_repeat
      end

      yield

      @repeat = @repeat.father
    end

    def tuple &block
      

    end

    def method_missing method, *args, &block
      if @kw_dispatcher[method]
        notify_syntax @kw_dispatcher[method], :before, method
        notify_listener :before_keyword, method

        result = @kw_dispatcher[method].send method, *args, &block
        result.freeze

        notify_syntax @kw_dispatcher[method], :after, method, result
        notify_listener :after_keyword, method, result
        return result
      end

      if @wd_dispatcher[method]
        notify_syntax @wd_dispatcher[method], :before, method
        notify_listener :before_word, method

        result = @wd_dispatcher[method].send method, *args, &block
        result.freeze

        notify_syntax @wd_dispatcher[method], :after, method, result
        notify_listener :after_word, method, result
        return result
      end
      super
    end

    private

    def clean
      @kw_dispatcher.clear
      @wd_dispatcher.clear
      @listener.clear
    end

    def notify_syntax syntax, time, keyword, *args
      callback = "#{ time }_#{ keyword }".to_sym
      syntax.send callback, *args if syntax.respond_to? callback
    end

    def notify_listener *args
      @listeners.each do |l|
        l.send *args
      end
    end
  end
end

if __FILE__ == $0
  script = IO.readlines($*[0]).join
  puts Miner::Worker.work script
end
