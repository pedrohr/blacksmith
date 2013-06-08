# -*- coding: utf-8 -*-
require 'rjb'
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

  def _load_object(filename)
    unless File.exists?(filename)
      return false
    end

    begin
      file = File.open(filename, 'r')
      obj = Marshal.load file.read
      file.close
      return obj
    rescue
      return false
    end
  end

  def load_pos_tagger
    maxent_tagger = Rjb::import('edu.stanford.nlp.tagger.maxent.MaxentTagger')

    @pos_tagger = maxent_tagger.new('lib/stanford-postagger-2013-04-04/models/wsj-0-18-bidirectional-nodistsim.tagger')
  end

  def load_stanford_parser
    Rjb::import('java.util.List')
    Rjb::import('java.io.Reader')
    Rjb::import('java.util.Iterator')
    Rjb::import('edu.stanford.nlp.ling.HasWord')
    Rjb::import('edu.stanford.nlp.ling.Sentence')
    Rjb::import('edu.stanford.nlp.trees.Tree')
    lp = Rjb::import('edu.stanford.nlp.parser.lexparser.LexicalizedParser')
    ptlp = Rjb::import('edu.stanford.nlp.trees.PennTreebankLanguagePack')
    @javaDocPreProcessor = Rjb::import('edu.stanford.nlp.process.DocumentPreprocessor')
    @javaStringReader = Rjb::import('java.io.StringReader')

    @lexicalized_parser = lp.loadModel("lib/stanford-parser-2013-04-05/englishPCFG.ser.gz", [])
    @grammaticalStructureFactory = ptlp.new().grammaticalStructureFactory()
  end

  def load_libraries
    Rjb::load('lib/stanford-parser-postagger.jar', ['-Xmx256m'])
    load_stanford_parser
    load_pos_tagger
  end

  def initialize(sentences)
    @sentences = sentences

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

  def pos_tag_windows(windows_info)
    interest = windows_info["windows"][1]
    
    tagged_string = @pos_tagger.tagString(interest)

    return extract_tags(tagged_string)
  end

  def filter_dependency_path(dependency_path)
    filtered_dp = []
    dependency_path.each do |rel|
      rel = rel.split("(")
      indexes = rel[1].scan(/\d/)
      filtered_dp.push(rel[0] + "(" + indexes[0] + ", " + indexes[1] + ")")
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

      dp = dp[1..dp.size-2]

      dp = dp.split(",")

      path = []
      component = ""
      push = false
      dp.each do |el|
        unless push
          component = el
          push = true
        else
          path.push((component + "," + el).strip)
          push = false
          component = ""
        end
      end

      paths.push(path.sort)
    end

    return paths.flatten
  end
end
