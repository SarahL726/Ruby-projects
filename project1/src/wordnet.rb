require_relative "graph.rb"

class Synsets
  attr_reader :Synsets

  def initialize
    @Synsets = Hash.new
  end

  def load(synsets_file)
    f = File.open(synsets_file, "r")
    index = 1 # line index
    indexes = Array.new # the return array
    valid = Hash.new
    while !f.eof
      line = f.readline
      # check the format
      if line =~ /^id: (\d+) synset: (.+)$/
        id = $1.to_i
        value = $2
        nouns = value.split(',')
        if id < 0 || @Synsets.has_key?(id) || nouns.length == 0 || valid.has_key?(id)
          indexes.push(index)
        else
          valid[id] = nouns
        end
      else
        indexes.push(index)
      end
      index += 1
    end
    f.close
    # all lines are valid
    if indexes.length == 0
      valid.each do |id, nouns|
        addSet(id, nouns)
      end
    else
      return indexes
    end
    return nil
  end

  def addSet(synset_id, nouns)
    if synset_id < 0 || @Synsets.has_key?(synset_id) || nouns == []
      return false
    else
      @Synsets[synset_id] = nouns
    end
    true
  end

  def lookup(synset_id)
    if @Synsets.has_key?(synset_id)
      return @Synsets[synset_id]
    end
    Array.new
  end

  def findSynsets(to_find)
    if to_find.instance_of?(String)
      ids = Array.new
      @Synsets.each do |id, nouns|
        if nouns.include?(to_find)
          ids.push(id)
        end
      end
      return ids
    elsif to_find.instance_of?(Array)
      hashes = Hash.new
      for i in 0...to_find.length
        ids = Array.new
        @Synsets.each do |id, nouns|
          if nouns.include?(to_find[i])
            ids.push(id)
          end
        end
        hashes[to_find[i]] = ids
      end
      return hashes
    else
      return nil
    end
  end
end

class Hypernyms
  attr_reader :vertex

  def initialize
    @Hypernyms = Graph.new
    @vertex = @Hypernyms.vertices
  end

  def load(hypernyms_file)
    f = File.open(hypernyms_file, "r")
    index = 1 # line index
    indexes = Array.new # the return array
    valid = Hash.new
    while !f.eof
      line = f.readline
      if line =~ /^from: (\d+) to: (.*)$/
        from = $1.to_i
        to = $2
        to_array = to.split(',')
        if from < 0
          to_array.each do |to|
            if to.to_i < 0 || to.to_i == source
              indexes.push(index)
            end
          end
        else
          valid[from] = to_array
        end
      else
        indexes.push(index)
      end
      index += 1
    end
    f.close

    if indexes.length == 0
      valid.each do |from, to_array|
        to_array.each { |to|
          addHypernym(from, to.to_i)
        }
      end
    else
      return indexes
    end
    return nil
  end

  def addHypernym(source, destination)
    if source < 0 || destination < 0 || source == destination
      return false
    else
      if !@Hypernyms.hasVertex?(source)
        @Hypernyms.addVertex(source)
      end
      if !@Hypernyms.hasVertex?(destination)
        @Hypernyms.addVertex(destination)
      end
      if !@Hypernyms.hasEdge?(source, destination)
        @Hypernyms.addEdge(source, destination)
      end
    end
    true
  end

  def lca(id1, id2)
    if !@Hypernyms.hasVertex?(id1) || !@Hypernyms.hasVertex?(id2)
      return nil
    end

    pt = id1
    curr = 0
    id1_bfs = @Hypernyms.bfs(id1)
    id2_bfs = @Hypernyms.bfs(id2)

    id1_bfs.each do |k, v|
      if id2_bfs.has_key?(k)
        if curr == 0
          curr = v + id2_bfs[k]
          pt = k
        else
          if curr > (v + id2_bfs[k])
            pt = k
            curr = v + id2_bfs
          end
        end
      end
    end

    result = Array.new(1, pt)
    return result
  end
end

class CommandParser
  def initialize
    @synsets = Synsets.new
    @hypernyms = Hypernyms.new
  end

  def parse(command)
    results = Hash.new()

    if command =~ /^\s*(\w+)\s*(.+)\s*$/
      valid_command = $1
      line = $2

      if valid_command == "load"
        results[:recognized_command] = :load

        if line =~ /^\s*(\S+)\s*(\S+)\s*$/
          synset_file = $1
          hypernym_file = $2
          is_valid = true
          temp_s = Synsets.new
          temp_h = Hypernyms.new

          if temp_s.load(synset_file) != nil || temp_h.load(hypernym_file) != nil
            results[:result] = false
          else
            temp_h.vertex.each do |v|
              if !@synsets.Synsets.keys.include?(v) && !temp_s.Synsets.keys.include?(v)
                is_valid = false
                break
              end
            end

            if is_valid
              if @synsets.load(synset_file) != nil || @hypernyms.load(hypernym_file) != nil
                results[:result] = false
              else
                results[:result] = true
              end
            else
              results[:result] = false
            end
          end
        else
          results[:result] = :error
        end
      elsif valid_command == "lookup"
        results[:recognized_command] = :lookup

        if line =~ /^(\d+)$/
          synset_id = $1.to_i
          if synset_id >= 0
            results[:result] = @synsets.lookup(synset_id)
          end
        else
          results[:result] = :error
        end
      elsif valid_command == "find"
        results[:recognized_command] = :find

        if line =~ /^(\w+)$/
          noun = $1
          results[:result] = @synsets.findSynsets(noun)
        else
          results[:result] = :error
        end
      elsif valid_command == "findmany"
        results[:recognized_command] = :findmany

        if line =~ /^(\S+)$/
          nouns = $1.split(',')
          results[:result] = @synsets.findSynsets(nouns)
        else
          results[:result] = :error
        end
      elsif valid_command == "lca"
        results[:recognized_command] = :lca

        if line =~ /^(\d+)\s+(\d+)$/
          id1 = $1.to_i
          id2 = $2.to_i
          if id1 > 0 && id2 > 0
            results[:result] = @hypernyms.lca(id1, id2)
          end
        else
          results[:result] = :error
        end
      else
        results[:recognized_command] = :invalid
      end
    else
      results[:recognized_command] = :invalid
    end
    return results
  end
end
