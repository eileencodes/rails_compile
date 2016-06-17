ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

module Kernel
  alias :my_require :require
  REQUIRED_FILES = {}
  CACHE_RATE = Hash.new 0
  required_files = 'required_files.marshal'

  if File.exists?(required_files)
    REQUIRED_FILES.merge!(Marshal.load(File.read(required_files)))
  end
  CACHE_KEY = REQUIRED_FILES.hash
  at_exit {
    if CACHE_KEY != REQUIRED_FILES.hash
      File.binwrite required_files, Marshal.dump(REQUIRED_FILES)
    end
  }


  def require(path)
    lf = $LOADED_FEATURES.dup
    if REQUIRED_FILES.key?(path)
      CACHE_RATE[:hit] += 1
      my_require(REQUIRED_FILES[path])
    else
      if path.start_with?("/")
        return my_require(path)
      end
      CACHE_RATE[:miss] += 1

      if my_require path
        new_path = ($LOADED_FEATURES - lf).last
        REQUIRED_FILES[path] = new_path
        true
      else
        false
      end
    end
  end
end
require 'bundler/setup' # Set up gems listed in the Gemfile.
