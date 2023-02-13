$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "deforest/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "deforest"
  s.version     = Deforest::VERSION
  s.authors     = ["Akshay Takkar"]
  s.email       = ["akshayt@m3india.in"]
  s.homepage    = "https://github.com/blackblood/deforest"
  s.summary     = "Deforest helps you analyze your method call stats"
  s.description = "Deforest tracks the number of times your model methods are called and presents it in digestable way. You can analyse and use this data to remove unused features/code"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  # s.add_dependency "rails", "~> 4.2.8"

  # s.add_runtime_dependency "sqlite3", "1.4.2"
  s.add_runtime_dependency "activerecord", "~> 4"
  s.add_runtime_dependency "activesupport", "~> 4"
  s.add_runtime_dependency "jquery-rails", "~> 4"

  s.add_development_dependency "bundler", "~> 1.17"
  s.add_development_dependency "rake"
  s.add_development_dependency "rails", "~> 4"
  s.add_development_dependency "sqlite3", "~> 1.3.11"
end
