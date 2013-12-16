Gem::Specification.new do |s|
  s.name        = 'classifier_atsukamoto'
  s.version     = '0.0.2'
  s.date        = '2013-12-13'
  s.summary     = "Classifier with Redis"
  s.description = "Classifier with redis"
  s.authors     = ["Lucas Carlson", "Afonso Tsukamoto"]
  s.email       = 'atsukamoto@faber-ventures.com'
  s.files       = [
                  "Rakefile",
                  "lib/classifier/extensions/string.rb",
                  "lib/classifier/extensions/vector.rb",
                  "lib/classifier/extensions/vector_serialize.rb",
                  "lib/classifier/extensions/word_hash.rb",
                  "lib/classifier/lsi/content_node.rb",
                  "lib/classifier/lsi/summary.rb",
                  "lib/classifier/lsi/word_list.rb",
                  "lib/classifier/bayes.rb",
                  "lib/classifier/lsi.rb",
                  "lib/classifier/redis_store.rb",
                  "lib/classifier_atsukamoto.rb",
                  "test/bayes/bayesian_test.rb"
                  ]
  s.add_runtime_dependency "ruby-stemmer", ["= 0.9.3"]
  s.homepage    = 'http://rubygems.org/gems/classifier_atsukamoto'
  s.license     = 'GNU'
end