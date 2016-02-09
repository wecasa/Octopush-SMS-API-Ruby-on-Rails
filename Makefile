.PHONY: test

console:
	irb -Ilib -roctopush-ruby

test:
	cutest test/*.rb
