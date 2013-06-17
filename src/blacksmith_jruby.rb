# -*- coding: utf-8 -*-
require 'java'
require 'lib/stanford-parser-postagger.jar'
require 'pp'
class Blacksmith
  SUMMARIZED_TAGS = {"$" => "ELSE",
      "``" => "ELSE",
      "''" => "ELSE",
      "(" => "ELSE",
      ")" => "ELSE",
      "," => "ELSE",
      "--" => "ELSE",
      "." => "ELSE",
      ":" => "ELSE",
      "CC" => "CONPREP",
      "CD" => "NUMBER",
      "DT" => "ADVERB",
      "EX" => "VERB",
      "FW" => "FORWORD",
      "IN" => "CONPREP",
      "JJ" => "ADJECT",
      "JJR" => "ADJECT",
      "JJS" => "ADJECT",
      "LS" => "ELSE",
      "MD" => "VERB",
      "NN" => "NOUN",
      "NNP" => "NOUN",
      "NNPS" => "NOUN",
      "NNS" => "NOUN",
      "PDT" => "ADVERB",
      "POS" => "POS",
      "PRP" => "NOUN",
      "PRP$" => "NOUN",
      "RB" => "ADVERB",
      "RBR" => "ADVERB",
      "RBS" => "ADVERB",
      "RP" => "ADVERB",
      "SYM" => "ELSE",
      "TO" => "CONPREP",
      "UH" => "ELSE",
      "VB" => "VERB",
      "VBD" => "VERB",
      "VBG" => "VERB",
      "VBN" => "VERB",
      "VBP" => "VERB",
      "VBZ" => "VERB",
      "WDT" => "ADVERB",
      "WP" => "NOUN",
      "WP$" => "NOUN",
      "WRB" => "ADVERB"}

  attr_reader :dbpedia_info, :sentences

  #Bag of Words
  attr_reader :bow_sentences, :bow_classes, :bow_dp, :bow_pos

  def _load_object(filename)
    unless File.exists?(filename)
      return {}
    end

    begin
      file = File.open(filename, 'r')
      obj = Marshal.load file.read
      file.close
      return obj
    rescue
      return {}
    end
  end

  def load_pos_tagger
    java_import('edu.stanford.nlp.tagger.maxent.MaxentTagger')

    @pos_tagger = MaxentTagger.new('lib/stanford-postagger-2013-04-04/models/wsj-0-18-bidirectional-nodistsim.tagger')
  end

  def load_stanford_parser
    java_import('java.util.List')
    java_import('java.io.Reader')
    java_import('java.util.Iterator')
    java_import('edu.stanford.nlp.ling.HasWord')
    java_import('edu.stanford.nlp.ling.Sentence')
    java_import('edu.stanford.nlp.trees.Tree')
    java_import('edu.stanford.nlp.parser.lexparser.LexicalizedParser')
    java_import('edu.stanford.nlp.trees.PennTreebankLanguagePack')
    java_import('edu.stanford.nlp.process.DocumentPreprocessor')
    java_import('java.io.StringReader')
    @javaDocPreProcessor = DocumentPreprocessor
    @javaStringReader = StringReader

    @lexicalized_parser = LexicalizedParser.loadModel("lib/stanford-parser-2013-04-05/englishPCFG.ser.gz")
    @grammaticalStructureFactory = PennTreebankLanguagePack.new().grammaticalStructureFactory()
  end

  def load_libraries
    load_stanford_parser
    load_pos_tagger
  end

  def initialize(sentences, classes_filename, bow_path)
    @sentences = sentences
    @classes = _load_object(classes_filename)

    @bow_path = bow_path

    load_libraries
  end

  def isolate_ids_and_pure_text(sentence)
    vec = []
    to_push = true

    return [""] if sentence.empty?

    sentence.split(" ").each do |token|
      if (token.include?("<") and token.include?(">"))
        
        left = token.match(/(.+)<.+/)
        unless left.nil?
          if (to_push)
            vec.push(left[1])
          else
            vec[vec.size-1] = vec.last + " " + left[1]
          end
        end

        vec.push(token.match(/(<.+>)/)[1])
        to_push = true

        right = token.match(/.+>(.+)/)
        unless right.nil?
          vec.push(right[1])
          to_push = false
        end
      else
        if (to_push)
          vec.push(token)
          to_push = false
        else
          vec[vec.size-1] = vec.last + " " + token
        end
      end
    end

    return vec
  end

  def extract_windows(sentence, k)
    tokens = isolate_ids_and_pure_text(sentence)
    
    left_window = ""
    inside_window = ""
    right_window = ""
    
    first_entity = false
    second_entity = false
    
    tokens.each do |token|
      if (token.include?("<") and token.include?(">"))
        unless first_entity
          first_entity = token
        else
          second_entity = token
        end
      elsif (first_entity)
        if (second_entity)
          right_window += token
        else
          inside_window += token
        end
      else
        left_window += token
      end
    end

    left = ""
    if k > 0
      left_window = left_window.split(" ")
      k.times do |i|
        left = left_window[left_window.size - 1 - i] + " " + left unless left_window[left_window.size - 1 - i].nil?
      end
    end

    right = ""
    if k > 0
      right_window = right_window.split(" ")
      k.times do |i|
        right += right_window[i] + " " unless right_window[i].nil?
      end
    end

    first_entity = first_entity[1..first_entity.length-2].split("/")
    second_entity = second_entity[1..second_entity.length-2].split("/")

    return {
      "windows" => [left.strip, inside_window.strip, right.strip], 
      "entities" => [[first_entity[0].gsub("_", " "), "/" + first_entity[1]], 
                     [second_entity[0].gsub("_", " "), "/" + second_entity[1]]]
    }
  end

  def extract_tags(tagged_string)
    tagged_tokens = tagged_string.split(" ")
    tags = []

    tagged_tokens.each do |tt|
      tags.push(SUMMARIZED_TAGS[tt.split("_")[1]])
    end

    return tags
  end

  def pos_tag_sentence(sentence)
    tagged_string = @pos_tagger.tagString(sentence)

    return extract_tags(tagged_string)
  end

  def pos_tag_windows(windows_info)
    return pos_tag_sentence(windows_info["windows"][1])
  end

  def filter_dependency_path(dependency_path)
    filtered_dp = []
    dependency_path.each do |rel|
      if rel == ""
        filtered_dp.push(rel)
      else
        rel = rel.split("(")
        if rel.nil?
          pp dependency_path
          pp rel
        end
        indexes = rel[1].scan(/\d/)
        filtered_dp.push(rel[0] + "(" + indexes[0] + ", " + indexes[1] + ")")
      end
    end
  
    return filtered_dp
  end

  def dependency_path(sentence)
    paths = []

    list_sentences = @javaDocPreProcessor.new(@javaStringReader.new(sentence))

    it = list_sentences.iterator()
    while it.hasNext()
      sentence = it.next()
      parse = @lexicalized_parser.apply(sentence)
      dp = @grammaticalStructureFactory.newGrammaticalStructure(parse).typedDependenciesCCprocessed().toString()

      if dp != "[]"
        dp.gsub!('[', '["')
        dp.gsub!(']', '"]')
        dp.gsub!('),', ')","')
        
        path = eval dp
        path.map! {|e| e.strip}
        
        paths.push(path.sort)
      else
        paths.push([""])
      end
    end

    return paths.flatten
  end

  def dependency_path_window(window_size_2)
    left_window = [""]
    right_window = [""]

    left_window.push(window_size_2["entities"][0][0].split(" "))
    right_window.push(window_size_2["entities"][1][0].split(" "))

    left_window.flatten!
    right_window.flatten!

    lw = window_size_2["windows"][0].split(" ")
    while left_window.size < 3 and lw.size != 0 do
      left_window.push(lw.pop)
    end

    rw = window_size_2["windows"][2].split(" ").reverse!
    while right_window.size < 3 and rw.size != 0 do
      right_window.push(rw.pop)
    end

    dp_window = []
    left_window.each do |l|
      right_window.each do |r|
          sentence = l + " " + window_size_2["windows"][1] + " " + r
          dp_window.push(filter_dependency_path(dependency_path(sentence)))
      end
    end

    return dp_window
  end

  def extract_classes(window)
    classes = [window["entities"][0][1], window["entities"][1][1]]

    classes.map! {|c| @classes[c]}

    classes.size.times do |i|
      classes[i] = "owl:Thing" if classes[i].nil?
    end

    return classes
  end

  def extract_features(wikipedia_sentence)
    sentence = wikipedia_sentence[0]
    relation = wikipedia_sentence[1]
    
    windows = []
    [0,1,2].each do |i|
      windows.push(extract_windows(sentence, i))
    end

    middle = windows[0]["windows"][1]
    pos_middle = pos_tag_sentence(middle)

    left_1 = windows[1]["windows"][0]
    pos_left_1 = pos_tag_sentence(left_1)
    right_1 = windows[1]["windows"][2]
    pos_right_1 = pos_tag_sentence(right_1)

    left_2 = windows[2]["windows"][0]
    pos_left_2 = pos_tag_sentence(left_2)
    right_2 = windows[2]["windows"][2]
    pos_right_2 = pos_tag_sentence(right_2)

    dp = dependency_path_window(windows[2])

    classes = extract_classes(windows[0])

    return [middle, pos_middle, left_1, pos_left_1, right_1, pos_right_1, left_2, pos_left_2, right_2, pos_right_2, dp, classes[0], classes[1], relation]
  end

  def _populate_bow(search, bow, features_ml, i)
    if bow[search].nil?
      features_ml[i] = bow.size
      bow[search] = features_ml[i]
    else
      features_ml[i] = bow[search]
    end
  end
  
  def convert_features_to_ml(features_array)
    ml = []

    features_array.each do |fa|
      features_ml = []

      [0,2,4,6,8].each do |i|
        _populate_bow(fa[i], @bow_sentences, features_ml, i)
      end

      [1,3,5,7,9].each do |i|
        _populate_bow(fa[i].join(""), @bow_pos, features_ml, i)
      end

      cnt = 10
      fa[10].each do |path|
        _populate_bow(path.join(""), @bow_dp, features_ml, cnt)
        cnt += 1
      end

      [11, 12].each do |i|
        _populate_bow(fa[i], @bow_classes, features_ml, cnt)
        cnt += 1
      end

      features_ml[cnt] = fa[13]

      ml.push(features_ml)
    end

    return ml
  end

  def extract_ml_features_from_sentences
    pp "Loading BOW files..."
    @bow_sentences = _load_object("#{@bow_path}/bow_sentences_dump.gz")
    @bow_classes = _load_object("#{@bow_path}/bow_classes_dump.gz")
    @bow_dp = _load_object("#{@bow_path}/bow_dp_dump.gz")
    @bow_pos = _load_object("#{@bow_path}/bow_pos_dump.gz")

    features_array = []
    i = 1
    @sentences.each do |sentence|
      print "\rExtracting features of sentence #{i} of #{sentences.size}"
      begin
        features_array.push(extract_features(sentence))
      rescue
        pp sentence
      end
      i += 1
    end

    features_to_ml = convert_features_to_ml(features_array)

    pp "Creating BOW hashes dump..."
    bow_sentences_dump = Marshal.dump(@bow_sentences)
    bow_pos_dump = Marshal.dump(@bow_pos)
    bow_dp_dump = Marshal.dump(@bow_dp)
    bow_classes_dump = Marshal.dump(@bow_classes)

    pp "Writing BOW hashes into disk..."
    File.open("#{@bow_path}/bow_sentences_dump.gz", "w") {|f| f.write(bow_sentences_dump)}
    File.open("#{@bow_path}/bow_pos_dump.gz", "w") {|f| f.write(bow_pos_dump)}
    File.open("#{@bow_path}/bow_dp_dump.gz", "w") {|f| f.write(bow_dp_dump)}
    File.open("#{@bow_path}/bow_classes_dump.gz", "w") {|f| f.write(bow_classes_dump)}
    
    return features_to_ml
  end
end
