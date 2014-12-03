module ManagedImage::VariantClass

  # Returns a hexdigest for security
  def hexdigest_for(s)
    Digest::MD5.hexdigest(s)
  end

  # Returns all the information about the variant as a Struct from the path
  def info_from_path(path, hexdigest)
    basename = File.basename(path, '.*')
    extname = File.extname(path)
    segments = path.split('/')    # segments of the path on '/'
    slices = basename.split('-')  # slices of the basename on '-'
    original_filename = slices[0..2].join('-') + extname
    OpenStruct.new(
      directory: File.dirname(path),
      basename: basename,
      # segments: segments,
      width: slices[3].to_i,
      height: slices[4].to_i,
      x1: slices[5].to_i,
      y1: slices[6].to_i,
      x2: slices[7].to_i,
      y2: slices[8].to_i,
      original_width: slices[1].to_i,
      original_height: slices[2].to_i,
      original_filename: original_filename,
      original_path: (segments[0..-2] + [original_filename]).join('/')
    )
  end

  # Returns a Variant object based on the path and the given hexdigest.
  def from_path(path, hexdigest)
    info = info_from_path(path, hexdigest)
    image = ManagedImage.new(
      info.original_path, 
      info.original_width, 
      info.original_height
    )
    variant = image.new_variant(info.width, info.height, info.x1, info.y1, info.x2, info.y2)
    variant.authenticated = variant.hexdigest == hexdigest
    variant
  end

end