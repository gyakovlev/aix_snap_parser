
# Parse the configuration file
# and provide methods to access FullFile and ParsedFile objects.
class ParserConfig

  # * +yaml_file+ * - the configuration file with instructions to parse the snap
  def initialize(yaml_file)
    @config=YAML::load_file(yaml_file)
  end

  # return every excel sheet listed in the configuration file
  def sheets
    result=full_sheets + parsed_sheets
    result.uniq
  end

  # Iterate over every full file listed in configuration file
  # and return a FullFile object to the block
  def each_full_file
    @config["full_files"].collect  { |file, conf| yield(FullFile.new(file, conf) ) }
  end

  # Iterate over every parsed file listed in configuration file
  # and return a ParsedFile object to the block
  def each_parsed_file
    @config["parsed_files"].collect  { |file, conf| yield(ParsedFile.new(file, conf) ) }
  end

  private

  def full_sheets
    @config["full_files"].collect { |k,v| v['sheet'] }
  end

  def parsed_sheets
    result=@config["parsed_files"].collect do |k,v|
      v["patterns"].collect do |k2,v2|
        v2["sheet"]
      end
    end
    result.flatten
  end
end