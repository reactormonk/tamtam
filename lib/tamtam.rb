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
class TamTam
  UNSUPPORTED = /(::first-letter|:link|:visited|:hover|:active)$/
  
  PSEUDO_ELEMENTS = /(:first-letter|:first-line|:before|:after)$/ 
  PSEUDO_CLASSES = /(:active|:focus|:hover|:link|:visited|:first-child|:lang)$/
  
  class << self
    def inline(args)
      css, doc = process(args)
      raw_styles(css).each do |raw_style|
        style, contents = parse(raw_style)        
        next if style.match(UNSUPPORTED)
        (doc/style).each do |element|
          apply_to(element, style, contents)
        end
      end
      doc.to_s
    end
   
    def specificity(css)
      specified_css = {}
      raw_styles(css).each_with_index do |raw_style, index|
        selectors, declarations = parse(raw_style)        
        selectors.split(",").map{ |s| s.strip }.each do |selector|
          next if selector.match(UNSUPPORTED)
          specified_css[selector] = {:declarations => declarations}
          specified_css[selector][:specificity] = calculate_specificity(selector) 
          specified_css[selector][:index] = index
        end 
      end
      specified_css 
    end

    def calculate_selector_specificity(css, options = {:a => true, :b => true, :c => true, :index => true} )
      specified_css = {}
      raw_styles(css).each_with_index do |raw_style, index|
        selectors, declarations = parse(raw_style)        
        selectors.split(",").map{ |s| s.strip }.each do |selector|
          next if selector.match(UNSUPPORTED)
          specified_css[selector] = {:declarations => declarations}
          specified_css[selector][:a] = a_specificity(selector) if options[:a]
          specified_css[selector][:b] = b_specificity(selector) if options[:b]
          specified_css[selector][:c] = c_specificity(selector) if options[:c]
          specified_css[selector][:index] = index if options[:index]
        end 
      end
      specified_css 
    end

    private
      def calculate_specificity(selector)
        specificty = 0
        specificty += a_specificity(selector) * 100
        specificty += b_specificity(selector) * 10
        specificty += c_specificity(selector)
        specificty 
      end

      def a_specificity(selector)
        selector.scan(/#[\w-]+/).size
      end

      def b_specificity(selector)
        pieces = selector.split(" ")
        i = 0
        pieces.each do |piece|
          i += piece.scan(".").size
          i += piece.scan("*[").size
        end
        i
      end

      def c_specificity(selector)
        element_pieces = selector.split(" ").reject{|s| s =~ /^(#|\.|\*)/ }
        i = 0
        element_pieces.each do |element_piece|
          if element_piece.scan("+")
            elements = element_piece.split("+").reject{|s| s =~ /^(#|\.|\*)/ }
            i += elements.size
          else 
            i += 1
          end
        end
        i
      end
      
      def process(args)
        if args[:document]
          doc = Hpricot(args[:document])
          style = (doc/"style").first
          [(style && style.inner_html), doc]
        else
          [args[:css], Hpricot(args[:body])]
        end
      end
    
      def raw_styles(css)
        return [] if css.nil?
        css.gsub!(/[\r\n]/, " ")
        css.gsub!(/\/\*.*?\*\//, "")
        validate(css)
        # jamming brackets back on, wishing for look-behinds
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
        # Regex from CSS::Parse::Lite
        data = raw_style.match(/^\s*([^{]+?)\s*\{(.*)\}\s*$/)
        raise InvalidStyleException, "Trouble on style: #{style}" if data.nil?
        data.captures.map { |s| s.strip }
      end
      
      def apply_to(element, style, contents)
        return unless element.respond_to?(:get_attribute)
        current_style = to_hash(element.get_attribute(:style))
        new_styles = to_hash(contents).merge(current_style)
        element.set_attribute(:style, prepare(new_styles))
      rescue Exception => e
        raise Exception.new(e), "Trouble on style #{style} on element #{element}: #{e}"
      end
      
      def to_hash(style)
        return {} if style.nil?
        hash = {}
        pieces = style.strip.split(";").map { |s| s.strip.split(":").map { |kv| kv.strip } }
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
end

class InvalidStyleException < Exception
end  
# "Man Chocolate" (don't ask)
