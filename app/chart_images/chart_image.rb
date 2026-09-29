class ChartImage
  class_attribute :_path
  def self.path(path)
    self._path = path
  end

  class_attribute :_height
  def self.height(height = nil)
    if height
      self._height = height
    else
      _height
    end
  end

  class_attribute :_width
  def self.width(width = nil)
    if width
      self._width = width
    else
      _width
    end
  end

  def self.valid_token?(request_token)
    request_token == ENV['CHART_API_TOKEN']
  end

  def initialize(user)
    @user = user
  end

  def snapshot!(width = nil, height = nil)
    PageToImage.convert!(url(_path), width || _width, height || _height)
  end

  private

  def url(path)
    ['http://localhost:3000', 'charts', @user.id, path].join('/') + "?token=#{ChartImage.token}"
  end
end
