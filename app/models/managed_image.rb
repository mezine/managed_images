class ManagedImage

  extend ManagedImageClass
  include IsAssertions
  include ManagedImage::ResizeMethods
  
  attr_accessor :path, :width, :height, :variants

  def initialize(path, width, height)
    is path, String
    is width, Fixnum
    is height, Fixnum
    self.path = path
    self.width = width
    self.height = height
    self.variants = {}
  end

  def fog_directory
    ManagedImage.originals_storage.directories.get(File.dirname(path))
  end

  def open
    directory.files.get(File.basename(path)) do |f|
      ap 'f.length'
    end
  end

  def fog_file
    file = fog_directory.files.get(File.basename(path))    
  end

  def magick_image
    # returns an array of images of which we only want the first
    Magick::Image.from_blob(fog_file.body)[0]
  end

  def aspect
    self.width.to_f / self.height.to_f
  end

  def add_variant(name, width, height, x1, y1, x2, y2)
    is name, String
    self.variants[name] = new_variant(width, height, x1, x2, y1, y2)
    self
  end

  # Returns a Variant object
  def new_variant(width, height, x1, y1, x2, y2)
    is width, Fixnum
    is height, Fixnum
    is x1, Fixnum
    is x2, Fixnum
    is y1, Fixnum
    is y2, Fixnum
    subimage = ManagedImage::Variant.new self, width, height, x1, y1, x2, y2
    subimage.to_json
    subimage
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

end

# TEMPORARY
#
# Because whenever Rails reloads a module, we are losing all the configuration
# information!
ManagedImage.config do |config|
  config.set_originals_storage Fog::Storage.new(
    local_root: File.join(Rails.root.to_path, '.data/managed-images/originals'),
    provider: 'Local'
  )
  config.set_variants_storage Fog::Storage.new(
    local_root: File.join(Rails.root.to_path, '.data/managed-images/variants'),
    provider: 'Local'
  )
end