module ManagedImageConfig

  class << self

    include IsAssertions

    attr_reader :originals_storage, :variants_storage

    def config
      yield self
      finish
    end

    def set_originals_storage(storage)
      # ap '-------------------------------set originals storage'
      # ap storage.class
      # ap storage.class.superclass
      # is fog, Fog::Storage
      assert storage.respond_to?(:directories), "storage must be created using Fog::Storage.new"
      @originals_storage = storage
    end

    def set_variants_storage(storage)
      assert storage.respond_to?(:directories), "storage must be created using Fog::Storage.new"
      @variants_storage = storage
    end

    def finish
      # ap '**********************'
      # ap originals_storage
      # ap variants_storage
      # ap '**********************'
      assert !originals_storage.nil?, "original_storage required"
      assert !variants_storage.nil?, "variants_storage required"
    end
  
  end

end