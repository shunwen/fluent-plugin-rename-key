# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-rename-key"
  gem.version     = "0.1.4"
  gem.license     = "Apache-2.0"
  gem.authors     = ["Shunwen Hsiao"]
  gem.email       = "hsiaoshunwen@gmail.com"
  gem.homepage    = "https://github.com/shunwen/fluent-plugin-rename-key"
  gem.summary     = %q[Fluentd output plugin. Rename keys which match given regular expressions, assign new tags and re-emit the records.]
  gem.has_rdoc    = false

  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_runtime_dependency "fluentd"
  gem.add_development_dependency "test-unit", ">= 3.1.0"
  gem.add_development_dependency "rake"
  gem.add_development_dependency 'coveralls'
end
