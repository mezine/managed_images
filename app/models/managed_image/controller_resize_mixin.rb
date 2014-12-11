module ManagedImage::ControllerResizeMixin

  # RESIZE METHODS
  #
  # These methods return a Variant JSON object.
  #
  # Each method takes an "image" param in the form as well as a
  # number of other arguments as specified in the method.
  #
  # NOTE:
  # This method does not return the actual image nor is it generated on the
  # server. The image is generated at the time the URL is requested.
  #
  # These methods should be access protected because the returned JSON objects
  # include URLs that can generate an image and therefore is a vector for a
  # denial of service attack.

  def manipulate
    image = ManagedImage.from_path(params[:image])
    variant = image.manipulate_from_params(params)
    render json: variant
  end

  # Resizes to fit the given width/height. Does not preserve aspect ratio.
  def resize
    image = ManagedImage.from_path(params[:image])
    width = params[:width].to_i
    height = params[:height].to_i
    render json: image.resize(width, height)
  end

  # Resizes to fit inside given width/height. Preserves the aspect ratio.
  # Makes Variant image smaller to fit.
  def resize_to_fit
    image = ManagedImage.from_path(params[:image])
    width = params[:width].to_i
    height = params[:height].to_i
    render json: image.resize_to_fit(width, height)
  end

  # Resizes to exact width/height. Crops edges to maintain aspect ratio.
  def resize_to_fill
    image = ManagedImage.from_path(params[:image])
    width = params[:width].to_i
    height = params[:height].to_i
    render json: image.resize_to_fill(width, height)
  end

  # Resizes to exact width/height. Crops edges to maintain aspect ratio.
  # Specify center (x/y) to fudge position of image.
  def resize_to_fill_at
    image = ManagedImage.from_path(params[:image])
    width = params[:width].to_i
    height = params[:height].to_i
    x = params[:x].to_f / 100
    y = params[:y].to_f / 100
    render json: image.resize_to_fill_at(width, height, x, y)
  end

  # Resize to fit the given rectangle (specified as percentages) to the exact
  # width/height. The client would be responsible for preserving the aspect
  # ratio in this case. The server would return exactly what the client
  # requested.
  def reframe
    image = ManagedImage.from_path(params[:image])
    width = params[:width].to_i
    height = params[:height].to_i
    x1 = params[:x1].to_i
    x2 = params[:x2].to_i
    y1 = params[:y1].to_i
    y2 = params[:y2].to_i
    render json: image.reframe(width, height, x1, y1, x2, y2)
  end

end