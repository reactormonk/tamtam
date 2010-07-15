$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")
require "tamtam"

describe TamTam do

  it "should inline a style onto a div with id" do
    css = '#foo { color: blue; }'
    body = '<div id="foo">woot</div>'    
    expected_output = '<div id="foo" style="color: blue;">woot</div>'
    TamTam.inline(:css => css, :body => body).should == expected_output
  end
  
  it "should inline a style onto a span with class" do
    css = 'span.woo-hoo { font-family: arial; }'
    body = '<span class="woo-hoo">woot</span>'    
    expected_output = '<span class="woo-hoo" style="font-family: arial;">woot</span>'
    TamTam.inline(:css => css, :body => body).should == expected_output    
  end
  
  it "should inline a style onto an h2" do
    css = 'h2 { margin: 5px; }'
    body = 'foo <h2>woot</h2> bar <h2>boot</h2> baz'    
    expected_output = 'foo <h2 style="margin: 5px;">woot</h2> bar <h2 style="margin: 5px;">boot</h2> baz'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end
  
  it "should inline a style with class and id" do
    css = '.foo, #bar { margin: -15px; font-size: 8px; }'
    body = 'x <span class="foo">woot</span> y <div id="bar">boot</div> z'
    expected_output = 'x <span class="foo" style="font-size: 8px; margin: -15px;">woot</span> y <div id="bar" style="font-size: 8px; margin: -15px;">boot</div> z'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end
  
  it "should inline a wildcard on everything" do
    css = '* { margin: 0 }'
    body = '<div>woot <span>foot</span></div> <b>grep</b>'
    expected_output = '<div style="margin: 0;">woot <span style="margin: 0;">foot</span></div> <b style="margin: 0;">grep</b>'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end

  it "should handle multi-line styles" do
    css = 'b { font-size: 8px;' + "\n" + 'font-color: blue; }'
    body = '<div>woot <span>foot</span></div> <b>grep</b>'
    expected_output = '<div>woot <span>foot</span></div> <b style="font-color: blue; font-size: 8px;">grep</b>'
    TamTam.inline(:css => css, :body => body).should == expected_output
  end

  it "should inline a style in a hierarchy" do
    css = '#foo .bar { font-size: 8px; }'
    body = '<div id="foo">woot <span class="bar">foot</span></div>'
    expected_output = '<div id="foo">woot <span class="bar" style="font-size: 8px;">foot</span></div>'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end
  
  it "should cascade styles on elements" do
    css = 'p { background: grey; }' + "\n" + '.normal { font-size: 12px; }'
    body = '<p class="normal" style="float: left">hi</p>'
    expected_output = '<p class="normal" style="background: grey; float: left; font-size: 12px;">hi</p>'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end

  it "should allow last style to win" do
    css = 'p { background: grey; }' + "\n" + '.normal { background: white; }'
    body = '<p class="normal" style="background: yellow">hi</p><p class="normal">and</p><p>good-bye</p>'
    expected_output = '<p class="normal" style="background: yellow;">hi</p><p class="normal" style="background: white;">and</p><p style="background: grey;">good-bye</p>'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end
  
  it "should ignore styles that don't apply to document" do
    # Pseudo elements/classes are not supported (and thus, ignored)
    css = '.flatbutton input[type=submit]:hover { background: #999; }' + "\n" + 'p { margin: 12px; }'
    body = '<div></div>'
    expected_output = '<div></div>'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end

  it "should handle blank css" do
    css = ''
    body = '<div></div>'
    expected_output = '<div></div>'
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end

  it "should handle blank body" do
    css = '.foo { color: black; }'
    body = ''
    expected_output = ''
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end

  it "should handle nil body" do
    css = '.foo { color: black; }'
    body = nil
    lambda { TamTam.inline(:css => css, :body => body) }.should raise_error(Exception)    
  end
  
  it "should not truncate urls" do
    css = '.foo { background: url("http://google.com/image.png") }'
    body = '<div class="foo"></div>'
    expected_output = %q(<div class="foo" style="background: url('http://google.com/image.png');"></div>)
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end
  
  it "should handle urls with semicolons" do
    css = ".foo { background: url(/images/blah;123.png); }"
    body = '<div class="foo"></div>'
    expected_output = %q(<div class="foo" style="background: url(/images/blah;123.png);"></div>)
    TamTam.inline(:css => css, :body => body).should == expected_output        
  end

  it "should handle unbalanced brackets in bad css" do
    css = '.foo { color: black;' + "\n" + '.bar { color: white; }'
    body = '<div class="foo"></div>'
    lambda { TamTam.inline(:css => css, :body => body) }.should raise_error(InvalidStyleException)
  end
  
  it "should handle an entire document with a stylesheet" do
    css = '#foo { font-color: blue; }'
    document = '<html><head><style>' + css + '</style></head><body><div id="foo">woot</div></body></html>'
    expected_output = '<html><head><style>' + css + '</style></head><body><div id="foo" style="font-color: blue;">woot</div></body></html>'
    TamTam.inline(:document => document).should == expected_output        
  end

  it "should handle an entire document without a stylesheet" do
    document = '<html><head></head><body><div id="foo">woot</div></body></html>'
    expected_output = '<html><head></head><body><div id="foo">woot</div></body></html>'
    TamTam.inline(:document => document).should == expected_output        
  end
  
  it "should handle a realistic situation" do
    css = open(File.join(File.dirname(__FILE__), "data", "twitter.css")).read
    body = open(File.join(File.dirname(__FILE__), "data", "twitter.html")).read
    expected_output = open(File.join(File.dirname(__FILE__), "data", "expected.html")).read
    TamTam.inline(:css => css, :body => body) == expected_output
  end  
 
  it "should ignore comments" do
    css = "/* div\n { background-color: black; } */ #foo { font-color: blue; } /* todo something */ #bar { font-size: 200%; }"
    document = '<html><head><style>' + css + '</style></head><body><div id="foo"><div id="bar">woot</div></div></body></html>'
    expected_output = '<html><head><style>' + css + '</style></head><body><div id="foo" style="font-color: blue;"><div id="bar" style="font-size: 200%;">woot</div></div></body></html>'
    TamTam.inline(:document => document).should == expected_output        
  end
 
  it "should not remove other declarations when applying new declarations" do
    css = %~
      p { 
        font-size: 10px;
        color: blue;
      }
      p.green {
        color: green;
      }
    ~
    body = '<html><head></head><body><p class="green">woot</p></body></html>'
    expected_output = '<html><head></head><body><p class="green" style="color: green; font-size: 10px;">woot</p></body></html>'
    TamTam.inline(:css => css, :body => body).should == expected_output
  end
  
  it "should choke on bad css" do    
    html = "<html>\n<head>\n<style>\np { font-size: pt; Viral Marketing &ndash; A developing media channel</span></p>\n                <p class=\"Copy\">Issue 4 - April 2008<br>\n                </p>\n                <p class=\"Copy\">A lot of research has come across our desk lately (and most probably yours), as to the success and viability of viral marketing. What we thought may be useful is a quick introduction, or review of:</p>\n                <p class=\"Copy\">&bull; What viral is<br>\n&bull; Where viral is heading<br>\n&bull; Viral limitations and opportunities </p>\n                <p class=\"Copy\">As you no doubt may be aware viral marketing started life in the realm of the online marketer, in areas like spam, or those annoying pop-up screens that keep appearing on your screen!}\n</style>\n</head>\n<body>\t\t\n<p>You can have my jellyfish <br />\n\tI'm not a sellyfish. ~ Ogden Nash\n</p>\n</body>\n</html>\n\t\t"
    lambda { TamTam.inline(:document => html) }.should raise_error(InvalidStyleException)
  end
  
  it "should remove data-tamtam directives" do
    document = '<html><head><style></style></head><body><div data-tamtam="ignore">foo</div><div>bar</div></body></html>'
    expected = '<html><head><style></style></head><body><div>foo</div><div>bar</div></body></html>'
    TamTam.inline(:document => document).should == expected        
  end
  
  it "should ignore elements with a data-tamtam='ignore' directive" do
    css = "div\n { color: black; }"
    document = '<html><head><style>' + css + '</style></head><body><div data-tamtam="ignore">foo</div><div>bar</div></body></html>'
    expected = '<html><head><style>' + css + '</style></head><body><div>foo</div><div style="color: black;">bar</div></body></html>'
    TamTam.inline(:document => document).should == expected        
  end

  it "should ignore elements that have a parent with a data-tamtam='ignore' directive" do
    css = "div\n { color: black; }"
    document = '<html><head><style>' + css + '</style></head><body><div data-tamtam="ignore"><div>foo</div></div><div><div>bar</div></div></body></html>'
    expected = '<html><head><style>' + css + '</style></head><body><div><div>foo</div></div><div style="color: black;"><div style="color: black;">bar</div></div></body></html>'
    TamTam.inline(:document => document).should == expected        
  end
  
  it "should apply styles to the root element" do
    css = "div { color: red; }"
    body = "<div>foo</div>"
    expected = '<div style="color: red;">foo</div>'
    TamTam.inline(:body => body, :css => css).should == expected
  end
  
end
