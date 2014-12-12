class ManagedImage::Variant

  extend ManagedImage::VariantClass
  include IsAssertions

  attr_accessor :parent_image, :width, :height, :x1, :x2, :y1, :y2, :authenticated

  def initialize(parent_image, width, height, x1, x2, y1, y2, authenticated=false)
    is parent_image, ManagedImage # parent
    is width, Fixnum
    is height, Fixnum
    is x1, Fixnum
    is x2, Fixnum
    is y1, Fixnum
    is y2, Fixnum
    assert authenticated == !!authenticated # boolean check
    validate_rect parent_image, width, height, x1, x2, y1, y2
    self.parent_image = parent_image
    self.width = width
    self.height = height
    self.x1 = x1
    self.x2 = x2
    self.y1 = y1
    self.y2 = y2
    self.authenticated = authenticated
  end

  # Returns the ManagedImage::Storage object for variants
  def storage
    ManagedImage.variants_storage
  end

  def authenticated?
    @authenticated
  end

  # returns the hexdigest for this specific path which is used for
  # authentication
  def hexdigest
    self.class.hexdigest_for(path)
  end

  # Returns the entire subpath
  def path
    "#{parent_image.basepath}-#{width}-#{height}-#{x1}-#{x2}-#{y1}-#{y2}#{parent_image.extname}"
  end

  def path_with_query
    "#{path}?q=#{hexdigest}"
  end

  # Returns the mime type based on the file extension
  def mimetype
    MIME::Types.type_for(parent_image.path).first.content_type
  end

  def exists?
    storage.exists?(path)
  end

  def destroy
    storage.destroy(path)
  end

  # Generates the image for the variant only if it doesn't already exist
  def generate
    if !self.exists?
      if !self.authenticated
        raise ManagedImage::AuthenticationError, "The ManagedImage::Variant has not been properly authenticated"
      end
      magick_image = parent_image.magick_image
      magick_image.crop!(*magick_crop_rect)
      # Only resize if the dimensions are incorrect
      if self.width != magick_image.columns || self.height != magick_image.rows
        magick_image.resize!(self.width, self.height)
      end
      storage.create(path, magick_image.to_blob)
    end
    self
  end

  # Return a BLOB that represents the file
  def blob
    generate
    storage.get(path).body
  end

  # Returns the URL for the variant image
  def url
    storage.url_for(path_with_query)
  end

  # Returns variant information as JSON
  def as_json(*args)
    {
      'image' => parent_image,
      'url' => url,
      'path' => path,
      'pathWithQuery' => path_with_query,
      'width' => width,
      'height' => height,
      'x1' => x1,
      'x2' => x2,
      'y1' => y1,
      'y2' => y2
    }
  end

private

  # Check to make sure the crop rectangle dimensions are valid
  def validate_rect image, width, height, x1, x2, y1, y2
    begin
      assert x1 >= 0
      assert x2 >= 0
      assert x1 <= image.width
      assert x2 <= image.width
      assert x1 <= x2
      assert y1 >= 0
      assert y2 >= 0
      assert y1 <= image.height
      assert y2 <= image.height
      assert y1 <= y2
    rescue => e
      raise ManagedImage::InvalidCropError, "Crop coordinates #{x1}, #{x2}, #{y1}, #{y2} is invalid for image with size #{image.width}x#{image.height}"
    end
  end

  # Returns a crop rectangle that Magick understands
  def magick_crop_rect
    [x1, y1, x2-x1, y2-y1]
  end


end