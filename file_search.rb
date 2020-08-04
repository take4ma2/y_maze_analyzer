module FileSearch
  module DirUtil
    def file_lists(directory, matcher)
      lists = Dir.glob("**/*", File::FNM_DOTMATCH, base: directory).select { |f| f.match(matcher) }
      lists.map{ |l| File.join(directory, l).encode('utf-8') }
    end

    def folder_name(directory)
      return nil unless File.directory? directory
      File.split(directory)[1]
    end
  end
  
  class FileUtil
    include DirUtil

    attr_accessor :matcher
    attr_accessor :directory
    attr_accessor :extension

    def initialize(directory, matcher, ext)
      @matcher = /_XY\.txt$/
      raise "引数でフォルダを指定してください。" if directory.nil?
      raise "#{directory}はディレクトリではありません。" unless File.directory?(directory)
      @directory = directory
      @extension = ext
    end

    def self.set(directory, matcher, ext)
      self.new directory, matcher, ext
    end

    def folder
      folder_name(@directory)
    end

    def files
      file_lists @directory, @matcher
    end

    def output_filename
      "#{folder}#{@extension}"
    end
  end
end
