class ManagedImage::Variant

  extend ManagedImage::VariantClass
  include IsAssertions

  attr_accessor :parent_image, :width, :height, :x1, :x2, :y1, :y2, :subimages, :authenticated

  def initialize(parent_image, width, height, x1, x2, y1, y2, authenticated=false)
    is parent_image, ManagedImage # parent
    is width, Fixnum
    is height, Fixnum
    is x1, Fixnum
    is x2, Fixnum
    is y1, Fixnum
    is y2, Fixnum
    assert authenticated == !!authenticated # boolean check
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
    self.class.hexdigest_for(subpath)
  end

  # Returns the entire subpath with the hexdigest appended to the end as "q"
  def path
    # hash = Digest::MD5.hexdigest(subpath)
    "#{subpath}?q=#{hexdigest}"
  end

  # Returns the mime type based on the file extension
  def mimetype
    MIME::Types.type_for(parent_image.path).first.content_type
  end

  # Takes the x1, x2, y1 and y2 coordinates (which are represented as
  # percentages) and converts it into pixel coordinates of x, y, width, height
  def crop_rect
    # convert to floats
    fx1 = self.x1.to_f / 100
    fy1 = self.y1.to_f / 100
    fx2 = self.x2.to_f / 100
    fy2 = self.y2.to_f / 100
    # convert to pixel rect
    px = (fx1*self.parent_image.width).round
    py = (fy1*self.parent_image.height).round
    pwidth = ((fx2-fx1)*self.parent_image.width).round
    pheight = ((fy2-fy1)*self.parent_image.height).round
    [px, py, pwidth, pheight]
  end

  # Generates the image for the variant only if it doesn't already exist
  def generate
    if !storage.exists?(subpath)
      if !self.authenticated
        raise ManagedImage::AuthenticationError, "The ManagedImage::Variant has not been properly authenticated"
      end
      magick_image = parent_image.magick_image
      magick_image.crop!(*crop_rect)
      magick_image.resize!(self.width, self.height)
      storage.create(subpath, magick_image.to_blob)
    end
    self
  end

  # Return a BLOB that represents the file
  def blob
    generate
    storage.get(subpath).body
  end

  def url
    storage.url_for(path)
  end

  # Returns variant information as JSON
  def as_json(*args)
    {
      'url' => url,
      'path' => path,
      'width' => width,
      'height' => height,
      'x1' => x1,
      'y1' => y1,
      'x2' => x2,
      'y2' => y2
    }
  end

  private

  # Returns the entire subpath
  def subpath
    "#{parent_image.basepath}-#{width}-#{height}-#{x1}-#{x2}-#{y1}-#{y2}#{parent_image.extname}"
  end

end