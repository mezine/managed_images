module ManagedImage::ControllerShowMixin

  # The image itself (the file) is returned from here.
  def show
    variant = ManagedImage::Variant.from_path("#{params[:path]}.#{params[:format]}", params[:q])
    send_data variant.blob, :type => variant.mimetype, :disposition => 'inline'
  end

end