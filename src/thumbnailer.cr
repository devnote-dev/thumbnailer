require "cling"
require "pluto"
require "pluto/format/jpeg"

class Thumbnailer::MainCommand < Cling::Command
  @path_arguments = Array(String).new

  def setup : Nil
    @name = "thumbnailer"

    add_option "width",
      description: "Set the width to create a thumbnail with, can be passed multiple times",
      default: [] of String,
      type: :multiple
    add_option "height",
      description: "Set the height to create a thumbnail with, can be passed multiple times",
      default: [] of String,
      type: :multiple
    add_option 'h', "help",
      description: "Show help information"
  end

  def on_missing_arguments(arguments : Array(String))
    puts "Missing required argument(s): #{format(arguments)}"
    exit 1
  end

  def on_unknown_arguments(arguments : Array(String))
    unknown_arguments = Array(String).new

    arguments.each do |argument|
      if File.exists?(argument)
        @path_arguments << argument
      else
        unknown_arguments << argument
      end
    end

    unless unknown_arguments.empty?
      puts "Unknown argument(s): #{format(unknown_arguments)}"
      exit 1
    end
  end

  def on_missing_options(options : Array(String))
    puts "Missing required option(s): #{format(options)}"
    exit 1
  end

  def on_unknown_options(options : Array(String))
    puts "Unknown option(s): #{format(options)}"
    exit 1
  end

  def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
    if options.has? "help"
      puts help_template

      false
    else
      true
    end
  end

  def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    @path_arguments.each do |file_path|
      image = File.open(file_path) do |file|
        Pluto::ImageRGBA.from_jpeg(file)
      end
      ratios = Array(Float64).new

      options.get("width").as_a.each do |width|
        ratios << image.width / width.to_i
      end

      options.get("height").as_a.each do |height|
        ratios << image.height / height.to_i
      end

      ratios.each do |ratio|
        file_name = Path.new(file_path).basename
        width = image.width // ratio
        height = image.height // ratio
        resized_image = image.bilinear_resize(width, height)

        io = IO::Memory.new
        resized_image.to_jpeg(io)
        io.rewind
        File.write("#{width}_#{height}_#{file_name}", io)
      end
    end
  end

  private def format(entries : Array(String)) : String
    entries.map { |entry| "`#{entry}`" }.join(", ")
  end
end

main_command = Thumbnailer::MainCommand.new
main_command.execute ARGV
