class HeadingBase
	attr_reader :title, :date, :house
  def initialize(title, count, url, date, house)
    @title, @count, @url, @date, @house = title, count, url, date, house
  end
  
  def id
    if @house.representatives?
      "uk.org.publicwhip/debate/#{@date}.#{@count}"
    else
      "uk.org.publicwhip/lords/#{@date}.#{@count}"
    end
  end

end

class MajorHeading < HeadingBase
  def output(x)
    x.tag!("major-heading", :id => id, :url => @url) { x << @title }
  end

	def couch_id
		['hansard','federal',@house.name,'major-heading',@date.to_s].to_key + '/' + @count.to_s
	end
end

class MinorHeading < HeadingBase
  def output(x)
    x.tag!("minor-heading", :id => id, :url => @url) { x << @title }
  end

	def couch_id
		['hansard','federal',@house.name,'minor-heading',@date.to_s].to_key + '/' + @count.to_s
	end
end
