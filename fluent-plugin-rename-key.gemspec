# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'fluent-plugin-rename-key'
  s.version     = '0.4.1'
  s.date        = '2017-02-27'
  s.license     = 'Apache-2.0'
  s.authors     = ['Shunwen Hsiao', 'Julian Grinblat', 'Hiroshi Hatake']
  s.email       = ['hsiaoshunwen@gmail.com']
  s.homepage    = 'https://github.com/shunwen/fluent-plugin-rename-key'
  s.summary     = %q[Fluentd output plugin. Rename keys which match given regular expressions, assign new tags and re-emit the records.]

  s.required_ruby_version = '>= 2.1.0'
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.add_runtime_dependency 'fluentd', ">= 0.14.0", "< 2"
  s.add_development_dependency 'test-unit', '~> 3.2'
  s.add_development_dependency 'rake', '~> 11.3'
  s.add_development_dependency 'coveralls', '~> 0.8'
end
