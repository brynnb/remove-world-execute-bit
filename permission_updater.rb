# PermissionUpdater class locates files with a world-execute bit enabled and disables that bit.
# It it defaults to present working directory if a path is not supplied.
# It accepts a `--max_depth` option to set how many levels deep to recursively find files (level 1 is the given path).
# If the `--recursive` option is set as true without any `--max_depth`, it will recursively
# find all files in all subdirectories. The `--all` option will also cause any hidden dot files
# to update as well.
#
class PermissionUpdater

  ALLOWED_PARAMS = ["max_depth", "path", "recursive", "verbose", "all"]

  def initialize(params = {})

    params.each do |key, value| # Make sure parameter is allowed
      key = key.to_s.downcase

      unless ALLOWED_PARAMS.include?(key)
        raise ArgumentError, "#{key}: parameter not valid"
      end

    end

    validate_parameters(params)

  end

  def get_updated_files
    @updated_files
  end

  def update_permissions
    processed_count = 0
    matched_count = 0

    @processed_files = []
    @updated_files = []

    get_files { |file|
      if world_executable?(file)

        remove_executable_bit(file)
        @updated_files << file
        if @verbose
          STDOUT.write "\nUpdated permission for #{file}"
        end

        matched_count += 1
      end

      processed_count += 1
      unless @verbose
        STDOUT.write "\r#{processed_count} files processed starting in #{@path} (#{matched_count} had world-execute permission removed)"
      end

      @processed_files << file

    }

    if @verbose # Provide summary at end
      STDOUT.write "\n#{processed_count} files processed starting in #{@path} (#{matched_count} had world-execute permission removed)"
    end

    STDOUT.write "\nProcessing complete."

    @processed_files

  end

  private

  def validate_parameters(params)

    unless params[:max_depth].nil?
      if !params[:max_depth].is_a?(Integer) || params[:max_depth] < 1
        raise ArgumentError, "max_depth: parameter must be a positive integer"
      end
    end

    @max_depth = params[:max_depth]

    @path = params[:path] || Dir.pwd

    unless @path.is_a? String #TODO: The class checks whether path exists elsewhere, but might be helpful to have here too
      raise ArgumentError, "path: parameter must be a string"
    end

    @recursive = validate_boolean params[:recursive], :recursive # Whether to check all subdirectories
    @all = validate_boolean params[:all], :all # Whether to include hidden dot files
    @verbose = validate_boolean params[:verbose], :verbose # Whether to output progress of updated files

  end

  def validate_boolean(test_var, name)
    if !test_var.nil? && !!test_var != test_var
      raise ArgumentError, "#{name}: parameter must be true or false"
    else
      test_var
    end

  end

  def get_files #TODO: This could probably be better broken up into smaller methods to not be so long
    paths = [@path] # Making an array because we'll push more as we go

    paths.each { |path|
      begin
        Dir.foreach(path) { |file|
          next if file == '.'
          next if file == '..'

          file = File.join(path, file)

          # Check for inaccessible files
          begin
            file_stat = File.send(:lstat, file)
          rescue Errno::ENOENT, Errno::EACCES
            next
          end

          # Escape brackets in directory name for use with Dir[]
          glob = File.join(File.dirname(file).gsub(/([\[\]])/, '\\\\\1'), '*')

          # Remove backslashes for use with Dir[]
          if File::ALT_SEPARATOR
            glob.tr!(File::ALT_SEPARATOR, File::SEPARATOR)
            file.tr!(File::ALT_SEPARATOR, File::SEPARATOR)
          end

          if @max_depth
            file_depth = file.split(File::SEPARATOR).length
            path_depth = [@path.split(File::SEPARATOR).length, 1].max # max() since splitting "/" results in empty array
            depth = file_depth - path_depth

            if depth > @max_depth
              next
            end
          end

          if @recursive || @max_depth
            if file_stat.directory?
              paths << file unless paths.include?(file) # Come back to directories later
            end
          end

          next unless File.ftype(file) == 'file' # Don't return non-files (like folders)

          unless @all
            next unless Dir[glob].include?(file) # Don't return hidden dot files
          end

          yield file

        }
      rescue Errno::EACCES
        next # Go to next file due to access error
      end
    }

  end

  # Method to check for the world execute permission
  #
  def world_executable?(file)
    begin
      file_stat = File.stat(file)
      return file_stat.mode & 0000001 != 0 #check if lowest bit is 1 to see whether world has execute permission
    rescue Errno::EACCESS
      false
    end

  end

  def remove_executable_bit(file)
    begin
      file_stat = File.stat(file)
      File.open(file).chmod(file_stat.mode - 1)
    rescue Errno::EACCESS
      false
    end

  end

end
