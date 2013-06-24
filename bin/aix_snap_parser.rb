# -*- coding: utf-8 -*-
#author: alain dejoux

require 'axlsx'
require 'optparse'
require 'yaml'
require 'rubygems/package'
require_relative '../lib/full_file'
require_relative '../lib/pattern'
require_relative '../lib/parsed_file'
require_relative '../lib/parser_config'
require_relative '../lib/snap_parser'

version=0.2

snap_file=""
config_file=""

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: analyse_snap.rb [-f snap_file] [-c config_file] [-h] [-v]"

  opts.on('-f snap', '--file=snap', 'snap file') do |v|
    snap_file = v
  end

  opts.on('-c config_file', '--config_file=config_file', 'yaml config file') do |v|
    config_file = v
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  opts.on_tail( '-v', '--version', 'Display tool version' ) do
    puts "version : #{version}"
    exit
  end
end
opt_parser.parse!

unless File.file?(snap_file)
  puts "error: file #{snap_file} is not readable"
  exit 1
end

#create xlsx file
p = Axlsx::Package.new
wb = p.workbook

#create styles
styles = wb.styles
header = styles.add_style(:bg_color => '00', :fg_color => 'FF', :b => true, :alignment => {:horizontal => :center})
standard = styles.add_style(:alignment => { :vertical => :top } )

#load configuration file
if config_file.empty?
  pc=ParserConfig.new('../config/snap.yml')
else
  pc=ParserConfig.new(config_file)
end

wb_sheets={}
#create summary worksheet
wb_sheets["summary"]=wb.add_worksheet(:name => "summary")
wb_sheets["summary"].add_row ["summary"], :style => header

#create sheet for each file in config
pc.sheets.each do |sheet|
  wb_sheets[sheet]=wb.add_worksheet(:name => sheet)
end

Gem::Package::TarReader.new(File.open(snap_file)).each do |entry|

  pc.each_full_file do |file|
    if entry.full_name.match(/#{file.name}/)
      row=wb_sheets[file.sheet].add_row [File.basename(entry.full_name)], :style => header
      wb_sheets[file.sheet].merge_cells("A#{row.index+1}:E#{row.index+1}")
      summary_row=wb_sheets["summary"].add_row [File.basename(entry.full_name)]

      wb_sheets["summary"].add_hyperlink :location => "'#{file.sheet}'!A#{row.index + 1}", :ref => "A#{summary_row.index + 1}", :target => :sheet
      entry.read.split("\n").each do |line|
        if file.skip_line and line.match(/#{file.skip_line}/)
          next
        end
        if file.skip_empty and line.chomp.empty?
          next
        end

        if file.separator.nil?
          wb_sheets[file.sheet].add_row [line]
        else
          wb_sheets[file.sheet].add_row line.split(file.separator, file.sep_num)
        end
      end
    end
  end

  pc.each_parsed_file do |file|
    if entry.full_name.match(/#{file.name}/)
      sp=SnapParser.new
      entry.read.split("\n").each do |line|
        if line.match(/^\.\.\.\.\./) and sp.previous_line.match(/^\.\.\.\.\./)
            sp.header=false
        end

        pattern_matched=false
        file.each_pattern do |pattern|
          if line.match(/^.....    #{pattern.name}/)
            sp.pattern=pattern
            row=wb_sheets[sp.pattern.sheet].add_row [line.sub(/^.....    /, '')], :style => header
            wb_sheets[sp.pattern.sheet].merge_cells("A#{row.index+1}:E#{row.index+1}")
            summary_row=wb_sheets["summary"].add_row [line.sub(/^.....    /, '')]
            wb_sheets["summary"].add_hyperlink :location => "'#{sp.pattern.sheet}'!A#{row.index + 1}", :ref => "A#{summary_row.index + 1}", :target => :sheet
            pattern_matched=true
            break
          end
        end

        next if pattern_matched

        if sp.header
          #puts "here #{line}"
          if line.match(/^\.\.\.\.\./)
            sp.previous_line = line
            next
          end

          unless line.chomp.empty?
            if sp.pattern.skip_line and line.match(/#{sp.pattern.skip_line}/)
              next
            end
            if sp.pattern.separator.nil?
              wb_sheets[sp.pattern.sheet].add_row [line]
            else
              wb_sheets[sp.pattern.sheet].add_row line.split(sp.pattern.separator, sp.pattern.sep_num)
            end
          end
        end
        sp.previous_line = line
      end
    end
  end
end

output_file=File.basename(snap_file).sub(/_.*/, '')
p.serialize("#{output_file}.xlsx")
