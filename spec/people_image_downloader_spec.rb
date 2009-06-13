require File.dirname(__FILE__)+'/spec_helper'

require "people_image_downloader"

describe PeopleImageDownloader do
  before do
    @snippet = Hpricot(<<-EOF)
<div class="box"><img title="RUDDOCK, the Hon. Philip Maxwell" alt="RUDDOCK, the Hon. Philip Maxwell" style="float: left; margin-top: 10px; margin-right: 10px; margin-bottom: 10px;" src="/parlInfo/download/handbook/allmps/0J4/upload_ref_binary/0j4.jpg"/><span class="sumLink">Biography for <span class="highlight"><strong>RUDDOCK</strong></span>, the Hon. <span class="highlight"><strong>Philip</strong></span> Maxwell</span><br/></div>
    EOF

    stub(Configuration).new.stub!

  end

  # NOTE excessive stubbing/mocking is a bit of a smell... counteract with integration
  it "parses out the image" do
    blob  = Object.new
    image = Object.new

    mock(MechanizeProxy).new.mock! do |proxy|
      proxy.cache_subdirectory = is_a(String)
      proxy.get('/parlInfo/download/handbook/allmps/0J4/upload_ref_binary/0j4.jpg').mock!.body {blob}
    end
    mock(Magick::Image).from_blob( blob ).mock![0].returns(image)

    @downloader = PeopleImageDownloader.new

    @downloader.extract_image(@snippet).should_not be_nil
  end
end
