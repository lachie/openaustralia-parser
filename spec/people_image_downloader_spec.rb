require File.dirname(__FILE__)+'/spec_helper'

require "people_image_downloader"

describe PeopleImageDownloader do
  before do
    @snippet = Hpricot(<<-EOF)
<div class="box"><img title="RUDDOCK, the Hon. Philip Maxwell" alt="RUDDOCK, the Hon. Philip Maxwell" style="float: left; margin-top: 10px; margin-right: 10px; margin-bottom: 10px;" src="/parlInfo/download/handbook/allmps/0J4/upload_ref_binary/0j4.jpg"/><span class="sumLink">Biography for <span class="highlight"><strong>RUDDOCK</strong></span>, the Hon. <span class="highlight"><strong>Philip</strong></span> Maxwell</span><br/></div>
    EOF

    o = Object.new
    stub(Configuration).new {o}
    stub(o).html_cache_path {'/tmp'}

    @downloader = PeopleImageDownloader.new
  end

  it "parses out the image" do
    @downloader.extract_image(@snippet).should_not be_nil
  end
end
