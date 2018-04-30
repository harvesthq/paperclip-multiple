# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paperclip/multiple/version'

Gem::Specification.new do |spec|
  spec.name          = "paperclip-multiple"
  spec.version       = Paperclip::Multiple::VERSION
  spec.authors       = ["Albert Llop"]
  spec.email         = ["mrsimo@gmail.com"]
  spec.summary       = "Storage backend for Paperclip to help migrate from one storage to another."
  spec.homepage      = "https://github.com/harvesthq/paperclip-multiple"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "paperclip"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "fog"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "appraisal"
end
