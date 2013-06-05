# -*- coding: utf-8 -*-
require 'test/unit'
require './src/blacksmith.rb'

SENTENCES = [['</Anarchism> is often defined as a </Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful', '/philosophy'],
     ['</Anarchism> as a mass </Social_movement> has regularly endured fluctuations in popularity', '/partOf'],
     ["The central tendency of </Anarchism> as a </Social_movement> has been represented by anarcho-communism and anarcho-syndicalism, with individualist anarchism being primarily a literary phenomenon which nevertheless did have an impact on the bigger currents and individualists have also participated in large anarchist organizations", '/partOf']]

    # Example of dbpedia_relations:
    # {"/Anarchism"=>
    #  {"/Political_philosophy" => "/philosophy", "/Social_movement" => "/partOf"},
    #  "/Irving_Shulman"=> {"/Rebel_without_a_case" => "/wrote"}}


BLACKSMITH = Blacksmith.new(SENTENCES)

class BlacksmitTest < Test::Unit::TestCase
  def setup
    # NOUN, VERB, ADVERB, ADJECT, NUMBER, CONPREP, POS, FORWORD, ELSE
    @summarized_tags = {"$" => "ELSE",
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

    @sentences = SENTENCES
    @blacksmith = BLACKSMITH
  end


  def test_should_load_sentences
    assert_equal(@blacksmith.sentences, @sentences)
  end

  def test_should_isolate_ids_and_pure_text
    assert_equal(@blacksmith.isolate_ids_and_pure_text('</Anarchism> is often defined as a </Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful'), ['</Anarchism>', 'is often defined as a', '</Political_philosophy>', 'which holds the state to be undesirable, unnecessary, or harmful'])
    assert_equal(@blacksmith.isolate_ids_and_pure_text('</Anarchism> as a mass </Social_movement> has regularly endured fluctuations in popularity'), ['</Anarchism>', 'as a mass', '</Social_movement>', 'has regularly endured fluctuations in popularity'])
    assert_equal(@blacksmith.isolate_ids_and_pure_text("The so-called-</Anarchism>'s father is </John>"), ["The so-called-", "</Anarchism>", "'s father is", "</John>"])
  end

  def test_should_extract_windows
    assert_equal(@blacksmith.extract_windows(@sentences[0][0], 0), ["", "is often defined as a", ""])
    assert_equal(@blacksmith.extract_windows(@sentences[1][0], 0), ["", "as a mass", ""])
    assert_equal(@blacksmith.extract_windows(@sentences[2][0], 0), ["", "as a", ""])

    assert_equal(@blacksmith.extract_windows(@sentences[0][0], 1), ["", "is often defined as a", "which"])
    assert_equal(@blacksmith.extract_windows(@sentences[1][0], 1), ["", "as a mass", "has"])
    assert_equal(@blacksmith.extract_windows(@sentences[2][0], 1), ["of", "as a", "has"])

    assert_equal(@blacksmith.extract_windows(@sentences[0][0], 2), ["", "is often defined as a", "which holds"])
    assert_equal(@blacksmith.extract_windows(@sentences[1][0], 2), ["", "as a mass", "has regularly"])
    assert_equal(@blacksmith.extract_windows(@sentences[2][0], 2), ["tendency of", "as a", "has been"])
  end

  def test_shuold_extract_tags
    return false
    assert_equal(@blacksmith.extract_tags("is_VBZ often_RB defined_VBN as_IN a_DT"), ["VERB", "ADVERB", "VERB", "CONPREP", "ADVERB"])
    assert_equal(@blacksmith.extract_tags("as_IN a_DT mass_NN"), ["CONPREP", "ADVERB", "NOUN"])
    assert_equal(@blacksmith.extract_tags("as_IN a_DT"), ["CONPREP", "ADVERB"])
  end

  def test_should_apply_a_POS_tagger_on_the_inside_window
    return false
    assert_equal(@blacksmith.pos_tag_windows(["", "as a mass", "has regularly"]), ["CONPREP", "ADVERB", "NOUN"])
    assert_equal(@blacksmith.pos_tag_windows(["", "is often defined as a", "which holds"]), ["VERB", "ADVERB", "VERB", "CONPREP", "ADVERB"])
    assert_equal(@blacksmith.pos_tag_windows(["tendency of", "as a", "has been"]), ["CONPREP", "ADVERB"])
  end

  # collapsed dependency path
  def test_should_extract_dependency_path
    assert_equal(@blacksmith.dependency_path("Astronomer Edwin Hubble was born in Marshfield, Missourdi."), ["auxpass(born-5, was-4)",
 "nn(Hubble-3, Astronomer-1)",
 "nn(Hubble-3, Edwin-2)",
 "nn(Missourdi-9, Marshfield-7)",
 "nsubjpass(born-5, Hubble-3)",
 "prep_in(born-5, Missourdi-9))",
 "root(ROOT-0, born-5)"])
  end
end
