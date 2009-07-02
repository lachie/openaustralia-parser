class String
  def to_key
    downcase.gsub(/[^a-z]+/,'-')
  end
end
