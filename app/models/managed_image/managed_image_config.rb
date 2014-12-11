module ManagedImage::ManagedImageConfig

  class << self

    include IsAssertions

    def image_config
      Rails.application.config.managed_image
    end

    def config
      Rails.application.config.managed_image = ActiveSupport::OrderedOptions.new
      # set default max upload image size to 8k
      set_max_upload_image_size(5000, 5000)
      # set default max originals image size to 2560px
      set_max_originals_image_size(2560, 2560)
      yield self
      finish
    end

    def set_salt(salt)
      is salt, String
      image_config.salt = salt
    end

    def set_original_storage(*args)
      raise "You probably meant to call set_originals_storage"
    end

    def set_originals_storage(storage)
      is storage, Hash
      storage = ManagedImage::Storage.new(storage)
      image_config.originals_storage = storage
    end

    def set_variants_storage(storage)
      is storage, Hash
      storage = ManagedImage::Storage.new(storage)
      image_config.variants_storage = storage
    end

    def set_max_upload_image_size(width, height)
      is width, Fixnum
      is height, Fixnum
      image_config.max_upload_image_size = OpenStruct.new(
        width: width,
        height: height
      )
    end

    def set_max_originals_image_size(width, height)
      is width, Fixnum
      is height, Fixnum
      image_config.max_originals_image_size = OpenStruct.new(
        width: width,
        height: height
      )
    end

    def finish
      is image_config.salt, String, "Call to set_salt required"
      is image_config.originals_storage, ManagedImage::Storage, "Call to set_originals_storage required"
      is image_config.variants_storage, ManagedImage::Storage, "Call to set_variants_storage required"
    end
  
  end
  
 end