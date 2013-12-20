# Author::    Lucas Carlson  (mailto:lucas@rufy.com)
# Copyright:: Copyright (c) 2005 Lucas Carlson
# License::   LGPL

module Classifier

require 'lingua/stemmer'

class Bayes
  # The class can be created with one or more categories, each of which will be
  # initialized and given a training method. E.g.,
  #      b = Classifier::Bayes.new 'Interesting', 'Uninteresting', 'Spam'
	def initialize(lang, *categories)
		#@categories = Hash.new
		#categories.each { |category| @categories[category.prepare_category_name] = Hash.new }
		# RedisStore.total_words = 0
		@categories = RedisStore.new lang, categories
		@categories.init_total
		@stemmer = Lingua::Stemmer.new(:language => lang.downcase)
	end

	#
	# Provides a general training method for all categories specified in Bayes#new
	# For example:
	#     b = Classifier::Bayes.new 'This', 'That', 'the_other'
	#     b.train :this, "This text"
	#     b.train "that", "That text"
	#     b.train "The other", "The other text"
	def train(category, text)
		category = category.prepare_category_name
		text.word_hash(@stemmer).each do |word, count|
			# @categories[category][word] ||= 0
			@categories.init(category, word)

			# @categories[category][word] += count
			@categories.incr(category, word, count)

			# @total_words += count
			@categories.incr_total(count)
		end
	end

	#
	# Provides a untraining method for all categories specified in Bayes#new
	# Be very careful with this method.
	#
	# For example:
	#     b = Classifier::Bayes.new 'This', 'That', 'the_other'
	#     b.train :this, "This text"
	#     b.untrain :this, "This text"
	def untrain(category, text)
		category = category.prepare_category_name
		text.word_hash(@stemmer).each do |word, count|
			# @total_words >= 0
			if @categories.total_words >= 0
				# orig = @categories[category][word]
				orig = @categories.get(category,word)

				# @categories[category][word] ||= 0
				@categories.init(category, word)

				# @categories[category][word] -= count
				@categories.decr(category, word, count)


				#if @categories[category][word] <= 0
				if @categories.get(category,word) <= 0
					# @categories[category].delete(word)
					@categories.remove(category,word)
					count = orig
				end
				#@total_words -= count
				@categories.decr_total(count)
			end
		end
	end

	#
	# Returns the scores in each category the provided +text+. E.g.,
	#    b.classifications "I hate bad words and you"
	#    =>  {"Uninteresting"=>-12.6997928013932, "Interesting"=>-18.4206807439524}
	# The largest of these scores (the one closest to 0) is the one picked out by #classify
	def classifications(text)
		score = Hash.new
		# actual categories saved in the beggining but each do |category|
		@categories.names.each do |category, category_words|
			score[category.to_s] = 0

			# total = category_words.values.inject(0) {|sum, element| sum+element}
			begin
				total = category_words.inject(0) { |sum, element| sum + element }
			rescue
				raise "Bayes needs to be trained before trying to classify"
			end

			text.word_hash(@stemmer).each do |word, count|
				#s = category_words.has_key?(word) ? category_words[word] : 0.1
				s = @categories.has_word?(category, word) ? @categories.get(category, word) : 0.1

				score[category.to_s] += Math.log(s/total.to_f)
			end
		end
		return score
	end

  #
  # Returns the classification of the provided +text+, which is one of the
  # categories given in the initializer. E.g.,
  #    b.classify "I hate bad words and you"
  #    =>  'Uninteresting'
	def classify(text)
		(classifications(text).sort_by { |a| -a[1] })[0][0]
	end

	#
	# Provides training and untraining methods for the categories specified in Bayes#new
	# For example:
	#     b = Classifier::Bayes.new 'This', 'That', 'the_other'
	#     b.train_this "This text"
	#     b.train_that "That text"
	#     b.untrain_that "That text"
	#     b.train_the_other "The other text"
	def method_missing(name, *args)
		category = name.to_s.gsub(/(un)?train_([\w]+)/, '\2').prepare_category_name
		# categories.has_key?(key)
		if @categories.names.include? category
			args.each { |text| eval("#{$1}train(category, text)") }
		elsif name.to_s =~ /(un)?train_([\w]+)/
			raise StandardError, "No such category: #{category}"
		else
	    super  #raise StandardError, "No such method: #{name}"
		end
	end

	#
	# Provides a list of category names
	# For example:
	#     b.categories
	#     =>   ['This', 'That', 'the_other']
	def categories # :nodoc:
		@categories
	end

	#
	# Allows you to add categories to the classifier.
	# For example:
	#     b.add_category "Not spam"
	#
	# WARNING: Adding categories to a trained classifier will
	# result in an undertrained category that will tend to match
	# more criteria than the trained selective categories. In short,
	# try to initialize your categories at initialization.
	def add_category(category)
		@categories[category.prepare_category_name] = Hash.new
	end

	alias append_category add_category
end

end
