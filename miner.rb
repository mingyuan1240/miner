# encoding: utf-8

current_dir = File.dirname(__FILE__)
$: << current_dir unless $:.include? current_dir
#$: << current_dir + "/main" unless $:.include? current_dir + "/main"

require 'element'
require 'syntax/random'
require 'syntax/cond'
require 'syntax/const'
require 'syntax/math'

module Miner
    class Worker 
        include Miner::Syntax::Random
        include Miner::Syntax::Const
        include Miner::Syntax::Math
        include Miner::Syntax::Cond

        def self.work(script)
            Worker.new.work script 
        end

        def work(script)
            instance_eval script
        end
    end
end

if __FILE__ == $0
   script = IO.readlines($*[0]).join
   puts Miner::Worker.work script
end
