module ManagedImageClass

  extend Forwardable
  include IsAssertions

  MAX_WIDTH = 1600
  MAX_HEIGHT = 1600

  def_delegators :'Rails.application.config.managed_image',
    :originals_storage, :variants_storage, :salt

  # Returns uploaded file src info
  def new_src_info(uploaded_file)
    path = uploaded_file.path
    hexdigest = Digest::MD5.file(path).hexdigest
    size = FastImage.size(path)
    if size.nil?
      raise "The uploaded file is not a valid Image"
    end
    OpenStruct.new(
      path: path,
      basename: File.basename(uploaded_file.original_filename, '.*'),
      extname: File.extname(uploaded_file.original_filename),
      hexdigest: hexdigest,
      width: size[0],
      height: size[1]
    )
  end

  # Returns new destination file info
  def new_dest_info(dir, src)
    filename = "#{src.hexdigest}-#{src.width}-#{src.height}#{src.extname}"
    OpenStruct.new(
      dir: dir,
      filename: filename,
      path: File.join(dir, filename)
    )
  end

  def new_variant_info(hash)
    width = hash[:width].to_i
    height = hash[:height].to_i
    x1 = hash[:x1] ? hash[:x1].to_i : 0
    x2 = hash[:x2] ? hash[:x2].to_i : 100
    y1 = hash[:y1] ? hash[:y1].to_i : 0
    y2 = hash[:y2] ? hash[:y2].to_i : 100
    width = 1 if width < 1
    height = 1 if height < 1
    width = MAX_WIDTH if width > MAX_WIDTH
    height = MAX_HEIGHT if height > MAX_HEIGHT
    x1 = 0 if x1 < 0
    x1 = 100 if x1 > 100
    x2 = 0 if x2 < 0
    x2 = 100 if x2 > 100
    y1 = 0 if y1 < 0
    y1 = 100 if y1 > 100
    y2 = 0 if y2 < 0
    y2 = 100 if y2 > 100
    OpenStruct.new(
      width: width,
      height: height,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2
    )
  end

  # Creates a ManagedImage object from an uploaded file. Optionally takes
  # a Hash that describes variants. This method is usuaally called from a
  # controller
  def upload(dir, uploaded_file, variants={})
    if !uploaded_file
      raise "There was no uploaded file for the image found"
    end
    is dir, String
    is uploaded_file, ActionDispatch::Http::UploadedFile
    is variants, Hash

    ap 'upload---------------'
    ap ManagedImage::MAX_FILE_SIZE
    ap uploaded_file.size
    if uploaded_file.size > ManagedImage::MAX_FILE_SIZE
      raise "The uploaded file must be less than #{ManagedImage::MAX_FILE_SIZE} bytes"
    end

    src = new_src_info(uploaded_file)
    dest = new_dest_info(dir, src)

    # Save the file to storage
    if !originals_storage.exists?(dest.path)
      File.open(src.path) do |f|
        originals_storage.create(dest.path, f)
      end
    end

    # Get the ManagedImage object
    image = self.new dest.path, src.width, src.height

    # Add variants to image
    variants.each do |key, variant_hash|
      v = new_variant_info(variant_hash)
      image.add_variant(key, v.width, v.height, v.x1, v.y1, v.x2, v.y2)
    end

    image
  end

  def image_info_from_path(path)
    slices = File.basename(path, '.*').split('-')
    width = slices[1].to_i
    height = slices[2].to_i
    OpenStruct.new(
      path: path,
      width: width,
      height: height
    )
  end

  def from_path(path)
    image_info = image_info_from_path(path)
    self.new(image_info.path, image_info.width, image_info.height)
  end

  def config(&block)
    ManagedImageConfig.config(&block)
  end
    
end