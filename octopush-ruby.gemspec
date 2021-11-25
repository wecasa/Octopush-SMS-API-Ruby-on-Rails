Gem::Specification.new do |s|
  s.name = "octopush-ruby"
  s.version = "0.0.1"
  s.summary = "A ruby library for use Octopush API"
  s.description = s.summary
  s.authors = ["César Carruitero"]
  s.email = ["cesar@mozilla.pe"]
  s.homepage = "https://github.com/ccarruitero/octopush-ruby"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency "nori"
  s.add_runtime_dependency "httparty"
  s.add_development_dependency "cutest"
end
