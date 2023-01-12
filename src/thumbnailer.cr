require "cli"
require "pluto"

class Thumbnailer::MainCommand < CLI::Command
  @path_arguments = Array(String).new

  def setup : Nil
    @name = "thumbnailer"

    add_option "widths",
      description: "Set widths to create thumbnails with (separated by comma)",
      has_value: true
    add_option "heights",
      description: "Set heights to create thumbnails with (separated by comma)",
      has_value: true
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

  def pre_run(arguments : CLI::ArgumentsInput, options : CLI::OptionsInput) : Bool
    if options.has? "help"
      puts help_template

      false
    else
      true
    end
  end

  def run(arguments : CLI::ArgumentsInput, options : CLI::OptionsInput) : Nil
    @path_arguments.each do |file_path|
      image = Pluto::Image.from_jpeg(File.read(file_path))
      ratios = Array(Float64).new

      if options.has?("widths")
        parse_sizes!(options.get!("widths")).each do |width|
          ratios << image.width / width
        end
      end

      if options.has?("heights")
        parse_sizes!(options.get!("heights")).each do |height|
          ratios << image.height / height
        end
      end

      ratios.each do |ratio|
        file_name = Path.new(file_path).basename
        width = image.width // ratio
        height = image.height // ratio
        resized_image = image.bilinear_resize(width, height)
        File.write("#{width}_#{height}_#{file_name}", resized_image.to_jpeg)
      end
    end
  end

  private def format(entries : Array(String)) : String
    entries.map { |entry| "`#{entry}`" }.join(", ")
  end

  private def parse_sizes!(value : CLI::Value) : Array(Int32)
    value.to_s.split(',').map(&.to_i)
  end
end

main_command = Thumbnailer::MainCommand.new
main_command.execute ARGV
