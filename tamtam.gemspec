Gem::Specification.new do |s|
        s.name = %q{tamtam}
        s.version = "0.0.3" 
        s.rubyforge_project = 'tamtam'
        s.date = %q{2007-10-05}
        s.summary = %q{Inline a CSS stylesheet into an HTML document.}
        s.description = %q{Email services like GMail and Hotmail don't like stylesheets. The only way around it is to use inline tags. Replacing stylesheet references with inline tags is a pain in the arse. Use this tool to do the dirty work for you.}
        s.email = %q{dave@obtiva.com}
        s.homepage = %q{http://tamtam.rubyforge.org/}
        s.authors = ["Dave Hoover"]
        s.require_paths = ['.','lib']
        s.add_dependency('hpricot')
        s.requirements = []
        s.files = ["lib/tamtam.rb"]
        s.autorequire = %q{tamtam}
end