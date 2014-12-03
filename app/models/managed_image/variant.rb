class ManagedImage::Variant

  extend ManagedImage::VariantClass
  include IsAssertions

  attr_accessor :parent_image, :width, :height, :x1, :x2, :y1, :y2, :subimages, :authenticated

  def initialize(parent_image, width, height, x1, x2, y1, y2)
    is parent_image, ManagedImage # parent
    is width, Fixnum
    is height, Fixnum
    is x1, Fixnum
    is x2, Fixnum
    is y1, Fixnum
    is y2, Fixnum
    self.parent_image = parent_image
    self.width = width
    self.height = height
    self.x1 = x1
    self.x2 = x2
    self.y1 = y1
    self.y2 = y2
  end

  def fog_directory
    # p ManagedImage.variants_storage
    # p parent_image.path
    directory = ManagedImage.variants_storage.directories.create(key: File.dirname(parent_image.path))
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
    fog_files = fog_directory.files
    basename = File.basename(subpath)
    if !fog_files.head(basename)
      magick_image = parent_image.magick_image
      magick_image.crop!(*crop_rect)
      magick_image.resize!(self.width, self.height)
      fog_file = fog_files.create(
        key: basename,
        body: magick_image.to_blob,
        public: true
      )
    end
    self
  end

  # Return a BLOB that represents the file
  def blob
    generate
    fog_file = fog_directory.files.get(File.basename(subpath))
    fog_file.body
  end

  # Returns variant information as JSON
  def as_json(*args)
    {
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