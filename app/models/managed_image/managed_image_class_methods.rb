module ManagedImage::ManagedImageClassMethods

  extend Forwardable
  include IsAssertions

  MAX_WIDTH = 1600
  MAX_HEIGHT = 1600

  def_delegators :'Rails.application.config.managed_image',
    :originals_storage,
    :variants_storage, :salt,
    :max_upload_image_size,
    :max_originals_image_size

  # Creates a ManagedImage object from an uploaded file. Optionally takes
  # a Hash that describes variants. This method is usuaally called from a
  # controller
  def upload(dir_argument, uploaded_file)
    dir = normalize_dir(dir_argument)
    is dir, String
    if !uploaded_file
      raise "There was no uploaded file for the image found"
    end

    assert uploaded_file.is_a?(ActionDispatch::Http::UploadedFile) || uploaded_file.is_a?(Rack::Test::UploadedFile)
    
    # if variants.nil?
    #   variants = {}
    # end
    # is variants, Hash

    # Check max file size
    if uploaded_file.size > ManagedImage::MAX_FILE_SIZE
      raise ManagedImage::UploadFileTooLargeError, "The uploaded file must be less than #{ManagedImage::MAX_FILE_SIZE} bytes"
    end

    max_upload_image_size = ManagedImage.max_upload_image_size

    src = new_src_info(uploaded_file)

    if src.width.nil? || src.height.nil?
      raise ManagedImage::InvalidImageError, "The uploaded file was not a recognized image"
    end

    if src.width > max_upload_image_size.width || src.height > max_upload_image_size.height
      raise ManagedImage::UploadImageTooLargeError, "Uploaded image which is #{src.width}x#{src.height} is too large. Must be less than #{max_upload_image_size.width}x#{max_upload_image_size.height}"
    end

    # Check to see if it needs to be resized
    image = nil
    if src.width > max_originals_image_size.width || src.height > max_originals_image_size.height
      magick_image = nil
      File.open(src.path, 'rb') do |io|
        magick_image = Magick::Image.from_blob(io.read)[0]
      end
      magick_image = magick_image.resize_to_fit(max_originals_image_size.width, max_originals_image_size.height)
      dest = new_dest_info(dir, src, magick_image.columns, magick_image.rows)
      originals_storage.create(dest.path, magick_image.to_blob)
      image = self.new dest.path, magick_image.columns, magick_image.rows
    else
      # If image doesn't need to be resized, then we pass io to the
      # storage's create method.
      dest = new_dest_info(dir, src, src.width, src.height)
      if !originals_storage.exists?(dest.path)
        File.open(src.path, 'rb') do |io|
          originals_storage.create(dest.path, io)
        end
      end
      # Get the ManagedImage object
      image = self.new dest.path, src.width, src.height
    end

    # # Add variants to image
    # variants.each do |key, variant_hash|
    #   v = new_variant_info(variant_hash)
    #   image.add_variant(key, v.width, v.height, v.x1, v.y1, v.x2, v.y2)
    # end

    image
  end

  def from_path(path)
    image_info = image_info_from_path(path)
    self.new(image_info.path, image_info.width, image_info.height)
  end

  def config(&block)
    ManagedImage::ManagedImageConfig.config(&block)
  end

private

  # Takes a directory as a String or an array of path segments and converts it
  # into a string. At the same time, we validate it.
  def normalize_dir(dir)
    if dir.is_a?(String)
      dir = File.split(dir)
    end
    is dir, Array
    dir.each do |segment|
      assert /^[0-9a-z\-_]+$/.match(segment), "each segment of the dir #{File.join(dir).inspect} must be alphanumeric or a '-'"
    end
    dir = File.join(dir)
    dir
  end

  # Returns uploaded file src info
  def new_src_info(uploaded_file)
    path = uploaded_file.path
    hexdigest = Digest::MD5.file(path).hexdigest
    # Check if too big to process
    image_size = nil
    File.open(path, 'rb') do |io|
      image_size = ImageSize.new(io)
    end
    OpenStruct.new(
      path: path,
      basename: File.basename(uploaded_file.original_filename, '.*'),
      extname: File.extname(uploaded_file.original_filename),
      hexdigest: hexdigest,
      width: image_size.width, # returns nil when image invalid
      height: image_size.height # returns nil when image invalid
    )
  end

  # Returns new destination file info
  def new_dest_info(dir, src, width, height)
    is dir, String
    is src, OpenStruct
    is width, Fixnum
    is height, Fixnum
    filename = "#{src.hexdigest}-#{width}-#{height}#{src.extname}"
    OpenStruct.new(
      dir: dir,
      filename: filename,
      path: File.join(dir, filename)
    )
  end

  # Returns a Struct with variant info based on a `params` hash.
  # That is, we expect the hash to have values that are Strings.
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

    
end