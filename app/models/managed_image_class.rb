module ManagedImageClass

  include IsAssertions

  MAX_WIDTH = 1600
  MAX_HEIGHT = 1600

  def originals_storage
    ManagedImageConfig.originals_storage
  end
 
  def variants_storage
    ManagedImageConfig.variants_storage
  end

  # Returns uploaded file src info
  def new_src_info(uploaded_file)
    path = uploaded_file.path
    hexdigest = Digest::MD5.file(path).hexdigest
    size = FastImage.size(path)
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


  # Takes an uploaded file in params[:file] and returns a ManagedImage object
  def from_params(dir, params)
    src = new_src_info(params[:file])
    dest = new_dest_info(dir, src)

    # create directory and file
    directory = originals_storage.directories.create(key: dest.dir)
    if directory.files.head(dest.filename).nil?
      File.open(src.path) do |f|
        directory.files.create(
          key: dest.filename,
          body: f,
          public: true
        )
      end
    end

    image = self.new dest.path, src.width, src.height
    if params[:variants]
      params[:variants].each do |key, variant_hash|
        v = new_variant_info(variant_hash)
        image.add_variant(key, v.width, v.height, v.x1, v.y1, v.x2, v.y2)
      end
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
    p '-------------------'
    self.new(image_info.path, image_info.width, image_info.height)
  end

  def config(&block)
    ManagedImageConfig.config(&block)
  end
    
end