# coding: utf-8

module Miner
    class GrammarError < StandardError
    end

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

    module Syntax
        module Base
            def self.included(mod)
                class << mod
                    def register_key(*keys)
                        keys.each do |key_method|
                            alias_name = "__#{ key_method }__".to_sym
                            alias_method alias_name, key_method
                            define_method(key_method) do |*args, **kws|
                                before key_method
                                send "before_#{ key_method }".to_sym

                                code = "#{alias_name} "
                                code << (0...args.size).map { |idx| "args[#{idx}]" }.join(",")
                                code << ",#{kws}" unless kws.empty?
                                result = instance_eval(code)
                                @tuple << result

                                after key_method
                            end
                        end
                    end
                end
            end

            def tuple
                @tuple = []

                yield

            end

            def ref(idx)
                @tuple[idx]
            end

            def repeat(times = 1)
                raise GrammarError, 'reapeat rule require a content' unless block_given?
                p yield 
            end

            private

            def before
                p 'before in base'
            end

            def after
                p 'after in base'
            end
        end
    end
end
