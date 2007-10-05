$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")
require "tamtam"

describe TamTam do

  it "should inline a style onto a div with id" do
    css = '#foo { font-color: blue; }'
    body = '<div id="foo">woot</div>'    
    expected_output = '<div id="foo" style="font-color: blue;">woot</div>'
    TamTam.inline(:css => css, :body => body).should == expected_output
  end
  
  it "should inline a style onto a span with class" do
    css = 'span.woo-hoo { font-family: arial; }'
    body = '<span class="woo-hoo">woot</div>'    
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
    TamTam.inline(:css => css, :body => body).size.should == expected_output.size
  end  
end