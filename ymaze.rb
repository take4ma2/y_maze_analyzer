require 'csv'
require './file_search'

module Ymaze
  
  EXP_TERMINATE = 8.0 * 60.0  # Experiment terminated at. (sec)
  SLICE_INTERVAL = 0.5         # Interval between slices (sec)
  SLICE_MAX = (EXP_TERMINATE / SLICE_INTERVAL).to_i - 1  # Max Slice
  
  class Ymaze
    
    attr_accessor :table, :animal, :box
    attr_accessor :positions
    attr_accessor :triplets

    def initialize(file)
      parse_ymaze_data file
      @triplets = Triplets.new @table
    end
    
    # open Y-maze data file
    # args, string, file ファイルパス
    # return nil
    def parse_ymaze_data(file)
      File.open(file,mode='rt:cp932:utf-8') do |f|
        
        f.gets("\nCD　Writing \tCD Writing OFF\t\t\t\t\t\t\t\t\t\t\t\t\t\n")
        @table = CSV.parse f, **{ :col_sep => "\t", :headers => true, :converters => :numeric, :header_converters => :symbol }
        @table = CSV::Table.new(@table[0..SLICE_MAX])
      end
      File.open(file,mode='rt:cp932:utf-8') do |f|
        f.each_line do |l|
          animal_id = /^Animal ID\t([^\t]+)/
          maze_no = /^Box ([0-9])/
          anm = l.match animal_id
          @animal = anm[1] if anm
          box = l.match maze_no
          @box = box[1] if box
        end
      end
    end

    def total_entry
      @table[:entry].select { |r| r == 1 }.size
    end
        
    def latency
      @table[:c].index(0).nil? ? @table[:c].length / 2.0 : ((@table[:c].index(0) + 1) / 2.0).ceil
    end

    def re_entry
      @table[:reentry].select { |r| r == 1 }.size
    end

    def distance
      @table[:distance].sum
    end

    def result
      rtn = {}
      rtn[:latency] = latency
      rtn[:total] = total_entry
      rtn[:triplets] = @triplets.count
      rtn[:alternate] = @triplets.alternative
      rtn[:spontaneous] = @triplets.spontaneous
      rtn[:distance] = distance
      rtn[:same] = re_entry
      rtn[:ratio_sp] = rtn[:triplets] > 0 ? rtn[:spontaneous].to_f / rtn[:triplets].to_f * 100.0 : 0.0
      rtn[:ratio_alternate] = rtn[:total] > 0 ? rtn[:alternate].to_f / rtn[:total].to_f * 100.0 : 0.0
      rtn[:ratio_same] = rtn[:total] > 0 ? rtn[:same].to_f / rtn[:total].to_f * 100.0 : 0.0
      rtn
    end

    def to_csv(header=false)
      head = ['Maze No.', 'Animal ID', 'Group Name', 'InitialPosition', 'Latency to exit start arm', 
              'Total arm entries', 'Number of triplets', 'Number of spontaneous alternations', 
              'Alternation ratio(%)', 'Number of alternate arm entries', 'Alternate arm entry ratio(%)',
              'Number of same arm entries','Same arm entry ratio(%)', 'Feacal boli', 'Total Distance(cm)']
      res = result
      data = [@box, @animal, '', 'C', res[:latency], res[:total], res[:triplets], res[:spontaneous],
              res[:ratio_sp], res[:alternate], res[:ratio_alternate], res[:same], res[:ratio_same], '', res[:distance]]
      csv = CSV.generate do |csv|
        csv << head if header
        csv << data
      end
      csv
    end

    def self.VERSION
      '1.1.0 (File search module and rename output names)'
    end
  end

  class Triplets
    attr_accessor :arm_positions
    attr_accessor :triplets
    def initialize(table)
      entered_arms table
    end

    def entered_arms(table)
      arms = table.select { |row| row[:entry] == 1 }
      @arm_positions = []
      arms.each do |row|
        @arm_positions << 'A' if row[:a] == 1
        @arm_positions << 'B' if row[:b] == 1
        @arm_positions << 'C' if row[:c] == 1
      end
      @triplets = []
      if arms.size >= 3 then
        [*0..@arm_positions.size-3].each do |index|
          @triplets << Triplet.new(@arm_positions[index], @arm_positions[index+1], @arm_positions[index+2])
        end
      end
    end

    def count
      @triplets.size
    end
    
    def spontaneous
      return 0 if @triplets.empty?
      @triplets.select { |t| t.spontaneous? }.size
    end

    def alternative
      return 0 if @triplets.empty?
      @triplets.select { |t| t.alternate? }.size
    end
  end

  class Triplet
    attr_accessor :p1, :p2, :p3

    def initialize(p1, p2, p3)
      @p1 = p1
      @p2 = p2
      @p3 = p3
    end


    def spontaneous?
      return @p1 != @p2 && @p2 != @p3 && @p3 != @p1
    end

    def alternate?
      return false if spontaneous?
      return @p1 == @p3 && @p1 != @p2
    end

    def re_entry?
      return true unless spontaneous? || alternate?
    end
  end
end


# --- main ---

folder = FileSearch::FileUtil.set(ARGV[0], /_XY.txt/, '_y.csv')
puts "Y maze data analyzer [v.#{Ymaze::Ymaze.VERSION}]"
File.open(folder.output_filename, 'w') do |fo|
  #target_files = File.expand_path File.join(ARGV[0], '*.txt')
  #Dir.glob(target_files.encode('utf-8')).each_with_index do |f, i|
  #Dir.glob(File.join('.', '検証用データフォルダ', 'I1026_EarlyY_8分', 'XYdata', '*.txt')).each_with_index do |f, i|
  folder.files.each_with_index do|f, i|
    puts "File No.#{i}: #{f}"
    ymaze = Ymaze::Ymaze.new File.join f
    if i == 0
      fo.puts ymaze.to_csv(true)
    else
      fo.puts ymaze.to_csv
    end
  end
end
