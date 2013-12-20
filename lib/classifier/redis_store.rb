module Classifier
	require 'redis'

	#if !String.instance_methods.include?(:underscore)
		class String
  		def underscore
  	  	self.gsub(/::/, '/').
  	  	gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
  	  	gsub(/([a-z\d])([A-Z])/,'\1_\2').
  	  	tr("-", "_").
  	  	downcase
  		end
		end
	#end

	class RedisStore
		include Enumerable

		attr_accessor :names

		def initialize(lang, categories)
			$redis = Redis.new
			@names = []
			@lang = lang
			categories.each_with_index do |category, index|
				@names << category.prepare_category_name
			end
		end

		def init(category, word)
			if !key_for?(category, word)
				insert(category, word, 0)
			end
		end

		def init_total
			$redis.set redis_total_key, 0
		end

		def total_words
			$redis.get(redis_total_key).to_i
		end

		def key_for?(category, word)
			$redis.exists(redis_key(category, word))
		end

		alias :has_word? :key_for?

		def insert(category, word, val)
			$redis.set(redis_key(category, word), "#{val}")
		end

		def get(category, word)
			val = $redis.get redis_key(category, word)
			val.nil? ? nil : val.to_i
		end

		def remove(category, word)
			$redis.del redis_key(category, word)
		end

		def incr(category, word, count)
			$redis.incrby redis_key(category, word), count.to_i
		end

		def incr_total(count)
			$redis.incrby redis_total_key, count.to_i
		end

		def decr
			$redis.decrby redis_key(category, word), count.to_i
		end

		def decr_total(count)
			$redis.decrby redis_total_key, count.to_i
		end

		def each(&block)
			#return enum_for(__method__) if block.nil?
			@names.each do |category|
				if block_given?
					block.call(category, get_by_wild_keys(category))
				else
					yield category
				end
			end
		end

		#protected

		def redis_key(category, word)
			"#{escape_lang}:#{escape_category(category)}:#{escape_word(word)}"
		end

		def redis_total_key
			"redis_bayes_store_#{@lang}"
		end

		def escape_category(category)
			category.to_s.gsub(" ", "_").downcase
		end

		def escape_word(word)
			word.to_s.force_encoding('UTF-8')
		end

		def escape_lang
			@lang.to_s.downcase
		end

		def get_by_wild_keys(category)
			wildlings = []
			$redis.keys("#{escape_lang}:#{escape_category(category)}:*").each do |key|
				wildlings << get_by_key(key).to_i
			end
			wildlings
		end

		def get_by_key(key)
			val = $redis.get(key)
			val.is_a?(String) ? eval(val) : val
		end
	end
end