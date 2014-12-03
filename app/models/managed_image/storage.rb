# Storage objects is where files go in ManagedImage.
#
# They are stored inside a Fog::Storage object. Note that Fog::Storage.new
# doesn't acctually return an instance of Fog::Storage (it's a factory).
#
# The initializer takes all the arguments of Fog::Storage.new but additionally
# allows the specification of a :dir and :url.
#
#   :dir specifies a subdirectory in Storage
#   :url specifies a base URL for the file path

class ManagedImage::Storage

  include IsAssertions

  attr_reader :dir, :fog_storage

  def initialize(opts)
    opts = opts.deep_dup
    @dir = opts[:dir]
    @url = opts[:url]
    is @dir, String
    is @url, String if @url
    opts.delete(:dir)
    @fog_storage = Fog::Storage.new(opts.to_hash)
  end

  # Takes a Fog file object and gets the public URL for it. If a :url was
  # specified during the creation of this storage object, we use that.
  # Otherwise we use the URL provided by the underline Fog::Storage object.
  def url_for(file)
    if self.dir
      raise "Not implemented yet."
    else
      file.public_url
    end
  end

end