# load support libs
Dir[ "#{File.dirname(__FILE__)}/user_agent/*.rb" ].each { |file| require file }

class UserAgent
  attr_reader :version, :match, :string
  
  def initialize str
    @string = str.to_s
    @string.strip!

    detect_user_agent unless @string.empty? || @string.size > 500
    @failed = @version.nil?
  end
  
  def failed?; @failed; end
  
  def msie?; @msie; end
  def firefox?; @firefox; end
  def chrome?; @chrome; end
  def safari?; @safari; end
  def opera?; @opera; end
  
  protected 
  
  def detect_user_agent
    # "jump away" for Opera using String#include? since it's quicker than regex at this point
    return parse_opera if @string.include?('Opera')
    
    match_for(:msie, /MSIE[ ]*(\d{1,2}\.[\dbB]{1,3})*/)       or 
    match_for(:firefox, /Firefox[ \(\/]*([a-z0-9\.\-\+]*)/i)  or
    match_for(:chrome, /Chrome\/([\d{1,3}\.]+)*/)             or
    parse_safari
  end
  
  ##
  # We need a special method just for Opera since it's user agent strings are a nightmare (see fixtures).
  # Opera's user-agent include various tokens and strings that try to make it look like MSIE or Firefox
  # Always set the browser to @opera since we know it is opera at this point
  def parse_opera
    match = match_agent(/Version\/(\d{1,2}\.\d{1,2})/) || match_agent(/Opera[ \(\/]*(\d{1,2}\.\d{1,2}[u1]*)/)
    
    set_version match.last if match
    @opera = true
  end
  
  # version map for Safari 
  @@safari_map = { :'2.0.4' => ['418.8', '419'], :'2.0.3' => ['417.9', '418'], :'2.0.2' => ['416.11', '416.12'], :'2.0.1' => ['412.7', '412.7'], 
                   :'2.0' => ['412', '412.6.2'], :'1.3.2' => ['312.8', '312.8.1'], :'1.3.1' => ['312.5', '312.5.2'], :'1.3' => ['312.1', '312.1.1'], 
                   :'1.2.4' => ['125.5.5', '125.5.7'], :'1.2.3' => ['125.4', '125.5'], :'1.2.2' => ['125.2', '125.2'], :'1.2' => ['124', '124'], 
                   :'1.0.3' => ['85.8.2', '85.8.5'], :'1.0' => ['85.7', '85.7'] }

  ##
  # We need a special method just to handle Safari since it's user agent strings are not
  # as easily parsed as other browsers. If everything fails, we will at least look for 'Safari'
  # in the user-agent string to positively match the vendor.
  def parse_safari
    unless match_for(:safari, /Version\/([\d{1,3}\.[dp1]*]+) Safari/)
      if match = match_agent(/AppleWebKit\/(\d{2,3}[\.\d{0,2}]*)/)
        # find may return nil so this is a two step process
        result = @@safari_map.find { |v, pair| match.last >= pair.first && match.last <= pair.last }
        set_version result.first.to_s if result
        
        @safari = true
        
      elsif @string.include?('Safari') || @string.include?('AppleWebKit')
        @safari = true
        
      end
    end
  end
  
  ##
  # Tries to match the user agent for the supplied browser via some regex
  # Regex are written so we at least can match the vendor
  def match_for browser, regex
    match = match_agent regex

    instance_variable_set "@#{browser}", true if match
    set_version match.to_a.last if match && match.size > 1
  end
  
  ##
  # Helper to make regex parsing a bit friendlier. It will convert the results to
  # an array and remove any nil or empty elements (or return nil if not match, the default behaviour)
  def match_agent regex
    match = @string.match regex
    return nil unless match
    
    match = match.to_a
    match.reject! { |m| m.nil? || m.empty? }
    
    match
  end
  
  ##
  # Quick helper method to make setting the version a bit easier
  def set_version version
    @version = BrowserVersion.new version
  end
end