class ManagedImage

  extend ManagedImage::ManagedImageClassMethods
  include IsAssertions
  include ManagedImage::ResizeMethods
  
  attr_accessor :path, :width, :height, :variants

  MAX_FILE_SIZE = 25 * 1024 * 1024

  def initialize(path, width, height)
    is path, String
    is width, Fixnum
    is height, Fixnum
    self.path = path
    self.width = width
    self.height = height
    self.variants = {}
  end

  # Returns the originals_storage ManagedImage::Storage object
  def storage
    ManagedImage.originals_storage
  end

  # Returns a Magick::Image object
  def magick_image
    # Magick::Image.from_blob returns an array of images of which we only want
    # the first
    Magick::Image.from_blob(storage.get(self.path).body)[0]
  end

  def aspect
    self.width.to_f / self.height.to_f
  end

  def add_variant(name, width, height, x1, x2, y1, y2)
    is name, String
    is width, Fixnum
    is height, Fixnum
    is x1, Fixnum
    is x2, Fixnum
    is y1, Fixnum
    is y2, Fixnum
    self.variants[name] = new_variant(width, height, x1, x2, y1, y2)
    self
  end

  # Returns a Variant object
  def new_variant(width, height, x1, x2, y1, y2)
    is width, Fixnum
    is height, Fixnum
    is x1, Fixnum
    is x2, Fixnum
    is y1, Fixnum
    is y2, Fixnum
    # Create an authenticated variant
    variant = ManagedImage::Variant.new(self, width, height, x1, x2, y1, y2, true)
    # variant.to_json
    variant
  end

  # Returns the entire subpath except the extension
  def basepath
    File.join(File.dirname(self.path), File.basename(self.path, '.*'))
  end

  # Returns the extension including the .
  def extname
    File.extname self.path
  end

  def as_json(*args)
    {
      'path' => path,
      'width' => width,
      'height' => height,
      'variants' => variants.as_json
    }
  end

  def to_document
    ManagedImage::ImageDocument.new(
      path: path,
      width: width,
      height: height
    )
  end

end


