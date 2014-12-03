class ManagedImage::ImageDocument

  include Mongoid::Document

  field :path, type: String
  field :width, type: Fixnum
  field :height, type: Fixnum

  def to_image
    ManagedImage.new(path, width, height)
  end

end