$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")
require "tamtam"

css = open(File.join(File.dirname(__FILE__), "..", "spec", "data", "twitter.css")).read
body = open(File.join(File.dirname(__FILE__), "..", "spec", "data", "twitter.html")).read

puts TamTam.inline(:css => css, :html => body)
