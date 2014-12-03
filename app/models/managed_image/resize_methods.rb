module ManagedImage::ResizeMethods

  def fixnum_percent(value)
    is value, Float
    int_value = (value * 100).round
    assert int_value >= 0
    assert int_value <= 100
    int_value
  end

  # Resizes image to fit inside the given target size while retaining its
  # aspect ratio.
  # The variant image returned may be smaller than the target size.
  def resize_to_fit(target_width, target_height)
    is target_width, Fixnum
    is target_height, Fixnum
    target_aspect = target_width.to_f / target_height.to_f
    if aspect > target_aspect
      variant_width = target_width 
      variant_height = (target_width / aspect).round
    else
      variant_width = (target_height * aspect).round
      variant_height = target_height 
    end
    new_variant(variant_width, variant_height, 0, 100, 0, 100)
  end

  def resize_to_fill(target_width, target_height)
    resize_to_fill_at(target_width, target_height, 0.5, 0.5)
  end

  # Resizes image to fit exactly in the given width/height retainings it aspect 
  # ratio and cropping any edges.
  #
  # x/y signifies the center of the image. To crop to the center of the image,
  # x=0.5 and y=0.5
  def resize_to_fill_at(target_width, target_height, x, y)
    is target_width, Fixnum
    is target_height, Fixnum
    is x, Float
    is y, Float
    assert x >= 0.0, "x must be greater than or equal to 0.0"
    assert x <= 1.0, "x must be less than or equal to 1.0"
    assert y >= 0.0, "y must be gerather than or equal to 0.0"
    assert y <= 1.0, "y must be less than or equal to 1.0"
    target_aspect = target_width.to_f / target_height.to_f
    if aspect > target_aspect
      y1 = 0.0
      y2 = 1.0
      total_padding = 1.0 - target_aspect / aspect
      max_offset = total_padding / 2.0
      target_offset = x - 0.5
      offset = [[target_offset, max_offset].min, -max_offset].max
      x1 = total_padding / 2.0 + offset
      x2 = 1.0 - total_padding / 2.0 + offset
    else
      x1 = 0.0
      x2 = 1.0
      inverse_aspect = 1.0 / aspect
      inverse_target_aspect = 1.0 / target_aspect
      total_padding = 1.0 - inverse_target_aspect / inverse_aspect
      max_offset = total_padding / 2.0
      target_offset = y - 0.5
      offset = [[target_offset, max_offset].min, -max_offset].max
      y1 = total_padding / 2.0 + offset
      y2 = 1.0 - total_padding / 2.0 + offset
    end
    new_variant(
      target_width, 
      target_height, 
      fixnum_percent(x1), 
      fixnum_percent(x2), 
      fixnum_percent(y1), 
      fixnum_percent(y2)
    )
  end

  def reframe(width, height, x1, y1, x2, y2)
    is width, Fixnum
    is height, Fixnum
    is x1, Float
    is y1, Float
    is x2, Float
    is y2, Float
    new_variant(
      width,
      height,
      fixnum_percent(x1),
      fixnum_percent(y1),
      fixnum_percent(x2),
      fixnum_percent(y2)
    )
  end

end