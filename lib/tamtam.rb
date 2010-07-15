require "rubygems"
require "hpricot"
# Takes CSS + HTML and converts it to inline styles.
# css    <=  '#foo { font-color: blue; }'
# html   <=  '<div id="foo">woot</div>'    
# output =>  '<div id="foo" style="font-color: blue;">woot</div>'
#
# The class uses regular expressions to parse the CSS.
# The regular expressions are based on CPAN's CSS::Parse::Lite.
#
# Author: Dave Hoover and Brian Tatnall of Obtiva Corp.
# Sponsor: Gary Levitt of MadMimi.com
module TamTam
  extend self
  
  UNSUPPORTED = /(:first-letter|:link|:visited|:hover|:active)(\s|$)/
  
  def inline(args)
    css, doc = process(args)
    raw_styles(css).each do |raw_style|
      style, contents = parse(raw_style)        
      next if style.match(UNSUPPORTED)
      (doc/style).each do |element|
        next if should_ignore?(element)
        apply_to(element, style, contents)
      end
    end
    remove_directives(doc)
    doc.to_s
  end
 
private
    
  def process(args)
    return_value =
    if args[:document]
      doc = Hpricot(args[:document])
      style = (doc/"style").first
      [(style && style.inner_html), doc]
    else
      [args[:css], Hpricot(args[:body])]
    end
    if args[:prune_classes]
      (doc/"*").each { |e| e.remove_attribute(:class) if e.respond_to?(:remove_attribute) }
    end
    return_value
  end
  
  def should_ignore?(element)
    el = element
    until el.nil? do
      return true if el.respond_to?(:attributes) and !el.attributes["data-tamtam"].nil? and el.attributes["data-tamtam"].match(/ignore/)
      el = el.parent
    end
  end
  
  def remove_directives(doc)
    (doc/'[@data-tamtam]').each do |element|
      element.remove_attribute("data-tamtam")
    end
  end

  def raw_styles(css)
    return [] if css.nil?
    css.gsub!(/[\r\n]/, " ") # remove newlines
    css.gsub!(/\/\*.*?\*\//, "") # strip /* comments */
    validate(css)
    # splitting on brackets and jamming them back on, wishing for look-behinds
    styles = css.strip.split("}").map { |style| style + "}" }
    # running backward to allow for "last one wins"
    styles.reverse
  end
  
  def validate(css)
    lefts = bracket_count(css, "{")
    rights = bracket_count(css, "}")
    if lefts != rights
      raise InvalidStyleException, "Found #{lefts} left brackets and #{rights} right brackets in:\n #{css}"
    end
  end
  
  def bracket_count(css, bracket)
    css.scan(Regexp.new(Regexp.escape(bracket))).size
  end
  
  def parse(raw_style)
    # Regex from CPAN's CSS::Parse::Lite
    data = raw_style.match(/^\s*([^{]+?)\s*\{(.*)\}\s*$/)
    raise InvalidStyleException, "Trouble on style: #{raw_style}" if data.nil?
    data.captures.map { |s| s.strip }
  end
  
  def apply_to(element, style, contents)
    return unless element.respond_to?(:get_attribute)
    current_style = to_hash(element.get_attribute(:style))
    new_styles = to_hash(contents).merge(current_style)
    element.set_attribute(:style, prepare(new_styles))
  rescue Exception => e
    raise InvalidStyleException, "Trouble on style #{style} on element #{element}"
  end
  
  def to_hash(style)
    return {} if style.nil?
    hash = {}
    # Split up the different styles,
    # can't just split on semicolons because they could be in url(foo;bar.png)
    styles = style.strip.scan(/((?:\(.*\)|[^;])+)/).flatten
    # Grab just the style name (color) and style body (blue),
    # making sure not to split on the colon in url(http://...), then
    # turn any double-quotes into single-quotes because Hpricot wants to escape double-quotes
    pieces = styles.map { |s| s.strip.split(":", 2).map { |kv| kv.strip.gsub('"', "'") } }
    pieces.each do |key, value|
      hash[key] = value
    end
    hash
  end
  
  def prepare(style_hash)
    sorted_styles = style_hash.keys.sort.map { |key| key + ": " + style_hash[key] }
    sorted_styles.join("; ").strip + ";"
  end
end

class InvalidStyleException < Exception
end  
# "Man Chocolate" (don't ask)
