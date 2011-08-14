require File.join(File.dirname(__FILE__), 'helper')
#puts "#{agent} EXEPECTED #{version} GOT #{ua.version}"  if ua.version != version
describe "AgentDetector" do
  it "marks as failed with empty user agents" do
    user_agent(nil).failed?.must_equal true
    user_agent('').failed?.must_equal true 
  end
  
  user_agent_fixtures.each do |fixture, versions|
    next unless versions
    
    browser = fixture.sub(/\.yml/, '')
    next if ENV['SKIP'].to_s.include? browser
    
    describe "#{browser.capitalize}" do
      versions.each do |version, list|

        # this isn't terribly DRY but it results better generated tests    
        if version.empty?
          it "matches browser with no versions" do
            list.each do |agent|
              ua = user_agent agent

              ua.failed?.must_equal true
              ua.version.must_be_nil
              ua.send("#{browser}?").wont_be_nil
            end
          end
        else        
          it "matches #{version}" do
            list.each do |agent|
              ua = user_agent agent

              ua.failed?.must_equal false
              ua.version.must_equal version
              ua.send("#{browser}?").wont_be_nil
            end
          end
        end
        
      end # each version
    end # describe block
    
    describe "#{browser.capitalize} performance" do
      agents = []
      versions.each { |v, list| agents += list }
      
      bench_performance_linear 'matching' do |n|
        n.times do
          user_agent agents[ rand(agents.size - 1) ]
        end
      end
    end
    
  end # each fixture 
end