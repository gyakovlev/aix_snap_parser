# This class define attributes for a file where sections will be matched.
#
class AdvancedParser < Parser

  # * +regexps+ - Define the expressions to use to detect a section to retrieve.
  attr_reader :matchexps

  # create a new object
  # * +file+ - parsed file name or regular expression used to retrieve it in snap archive
  # * +config+ - the config section associated to file
  def initialize(file, config)
    super
    @matchexps=[]
    @sheet=config['sheet']
    @exclude=config['exclude']
    @header=true
    config['matchs'].each_key do |pattern|
      @matchexps<<Matchexp.new(pattern,config['matchs'][pattern])
    end
  end

  def header?
    @header
  end

  def no_header!
    @header=false
  end

  # Iterate on each pattern and return a Pattern object to the block
  def each_matchexp
    @matchexps.each { |matchexp| yield(matchexp)}
  end
end
