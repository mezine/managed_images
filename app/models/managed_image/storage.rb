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

  attr_reader :dir, :url, :fog_storage

  def initialize(opts)
    opts = opts.deep_dup
    @dir = opts[:dir]
    @url = opts[:url] || ''
    is @dir, String
    is @url, String
    opts.delete(:dir)
    @fog_storage = Fog::Storage.new(opts.to_hash)
  end

  # Takes a Fog file object and gets the public URL for it. If a :url was
  # specified during the creation of this storage object, we use that.
  # Otherwise we use the URL provided by the underline Fog::Storage object.
  def url_for(path)
    if self.url
      File.join(url, path)
    else
      file.public_url
    end
  end

  # Create a Fog file object at the given path.
  # Because of our use case where there won't be a collission unless the
  # filenames are identical, if the file already exists, we don't overwrite it.
  def create(path, body)
    is path, String
    assert body.is_a?(IO) || body.is_a?(String)
    # is body, IO
    if !exists?(path)
      directory = fog_storage.directories.create(key: File.join(self.dir, File.dirname(path)))
      directory.files.create(
        key: File.basename(path),
        body: body,
        public: true
      )
    end
  end

  # Get a Fog file object and the given path
  def get(path)
    files = fog_directory(File.dirname(path)).files
    files.get(File.basename(path))
  end

  # Check to see if a Fog file exists at the given path
  def exists?(path)
    is path, String
    directory = fog_directory(File.dirname(path))
    directory ? !directory.files.head(File.basename(path)).nil? : false
  end

private

  # Returns a Fog::Directory object for the given dir. We automatically
  # prefix it with self.dir so that we get the proper subdirectory
  def fog_directory(dir)
    fog_storage.directories.get(File.join(self.dir, dir))
  end

  def directories
    fog_storage.directories
  end

  def files
    directories.files
  end

end