class String
  def to_key
    downcase.gsub(/[^a-z0-9]+/,'-')
  end
end
