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

# it should implement CSS2 specificty rules 
# http://www.w3.org/TR/REC-CSS2/cascade.html#specificity    

  it "should count the number of ID attributes in the selector (= a)" do 
    css = %~
      * {}
      LI {}
      UL LI {}
      UL OL+LI {} 
      UL OL LI.red {}
      LI.red.level {}
      H1 + *[REL=up] {}
      #x34y {}
      .c_1 { color: #333 } 
      #i_1 { font-size: 12; } 
      #i_1 #i_2 { border-size: 1px; }  
    ~
    expected_output = { 
      '*' => { :declarations => "", :a => 0 },
      'LI' => { :declarations => "", :a => 0 },
      'UL LI' => { :declarations => "", :a => 0 },
      'UL OL+LI' => { :declarations => "", :a => 0 },
      'UL OL LI.red' => { :declarations => "", :a => 0 },
      'LI.red.level' => { :declarations => "", :a => 0 },
       'H1 + *[REL=up]' => { :declarations => "", :a => 0 },
      '#x34y' => { :declarations => "", :a => 1 },
      '.c_1' => { :declarations => "color: #333", :a => 0 },
      '#i_1' => { :declarations => "font-size: 12;", :a => 1 },
      '#i_1 #i_2' => { :declarations => 'border-size: 1px;', :a => 2  }
    }
    TamTam.calculate_selector_specificity(css, {:a => true}).should == expected_output
  end

  it "should only count ID attributes that have attributes" do 
    css = %~
      ### {}
      li#i_1 #i_2 {}
    ~
    expected_output = { 
      '###' => { :declarations => "", :a => 0 },
      'li#i_1 #i_2' => { :declarations => "", :a => 2 },
    }
    TamTam.calculate_selector_specificity(css, {:a => true}).should == expected_output
  end

  it "should count the number of other attributes and pseudo-classes in the selector (= b)" do
    css = %~
      * {}
      LI {}
      UL LI {}
      UL OL+LI {} 
      UL OL LI.red {}
      LI.red.level {}
      H1 + *[REL=up] {}
      #x34y {}
      .c_1 { color: #333 } 
      #i_1 { font-size: 12; } 
      .c_1 .c_2 #i_1 { color: #fff; }
    ~ 
    expected_output = { 
      '*' => { :declarations => "", :b => 0 },
      'LI' => { :declarations => "", :b => 0 },
      'UL LI' => { :declarations => "", :b => 0 },
      'UL OL+LI' => { :declarations => "", :b => 0 },
      'UL OL LI.red' => { :declarations => "", :b => 1 },
      'LI.red.level' => { :declarations => "", :b => 2 },
       'H1 + *[REL=up]' => { :declarations => "", :b => 1 },
      '#x34y' => { :declarations => "", :b => 0 },
      '.c_1' => { :declarations => "color: #333", :b => 1 },
      '#i_1' => { :declarations => "font-size: 12;", :b => 0 },
      '.c_1 .c_2 #i_1' => { :declarations => 'color: #fff;', :b => 2  }
    }
    TamTam.calculate_selector_specificity(css, {:b => true} ).should == expected_output
  end
  
  it "should count the number of element names in the selector (= c)" do 
    css = %~
      * {}
      LI {}
      UL LI {}
      UL OL+LI {} 
      UL OL LI.red {}
      LI.red.level {}
      #x34y {}
      .c_1 { color: #333 } 
      #i_1 .c_1 li { font-size: 12; } 
      .c_1 .c_2 #i_1 { color: #fff; }
    ~ 
    expected_output = { 
      '*' => { :declarations => "", :c => 0 },
      'LI' => { :declarations => "", :c => 1 },
      'UL LI' => { :declarations => "", :c => 2 },
      'UL OL+LI' => { :declarations => "", :c => 3 },
      'UL OL LI.red' => { :declarations => "", :c => 3 },
      'LI.red.level' => { :declarations => "", :c => 1 },
      '#x34y' => { :declarations => "", :c => 0 },
      '.c_1' => { :declarations => "color: #333", :c => 0 },
      '#i_1 .c_1 li' => { :declarations => "font-size: 12;", :c => 1 },
      '.c_1 .c_2 #i_1' => { :declarations => 'color: #fff;', :c => 0 },
    }
    TamTam.calculate_selector_specificity(css, {:c => true} ).should == expected_output
  end

  it "should specify simple grouping" do 
    css = %~
      h1, h2, h3 {}
    ~ 
    expected_output = { 
      'h1' => { :declarations => "", :a => 0, :b => 0, :c => 1 },
      'h2' => { :declarations => "", :a => 0, :b => 0, :c => 1 },
      'h3' => { :declarations => "", :a => 0, :b => 0, :c => 1 } 
    }
    TamTam.calculate_selector_specificity(css).should == expected_output
  end
  
  it "should specify complex grouping" do 
    css = %~
      LI.red.level, #i_1 .c_1 li, UL OL+LI { color: blue; }
    ~ 
    expected_output = { 
      'LI.red.level' => { :declarations => "color: blue;", :a => 0, :b => 2, :c => 1 },
      '#i_1 .c_1 li' => { :declarations => "color: blue;", :a => 1, :b => 1, :c => 1 },
      'UL OL+LI' => { :declarations => "color: blue;", :a => 0, :b => 0, :c => 3 } 
    }
    TamTam.calculate_selector_specificity(css).should == expected_output
  end


end
