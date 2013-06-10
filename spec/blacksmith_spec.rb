# -*- coding: utf-8 -*-
require 'test/unit'
require './src/blacksmith.rb'

SENTENCES = [['<Anarchism/Anarchism> is often defined as a <political_philosophy/Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful', '/philosophy'],
             ['<Anarchism/Anarchism> as a mass <social_movement/Social_movement> has regularly endured fluctuations in popularity', '/partOf'],
             ["The central tendency of <anarchism/Anarchism> as a <social_movement/Social_movement> has been represented by anarcho-communism and anarcho-syndicalism, with individualist anarchism being primarily a literary phenomenon which nevertheless did have an impact on the bigger currents and individualists have also participated in large anarchist organizations", '/partOf']]

WINDOWS_SIZE_0 = [{"windows" => ["", "is often defined as a", ""], "entities" => [["Anarchism", "/Anarchism"], ["political philosophy", "/Political_philosophy"]]},
                  {"windows" => ["", "as a mass", ""], "entities" => [["Anarchism", "/Anarchism"],["social movement", "/Social_movement"]]},
                  {"windows" => ["", "as a", ""], "entities" => [["anarchism", "/Anarchism"], ["social movement", "/Social_movement"]]}]

WINDOWS_SIZE_1 = [{"windows" => ["", "is often defined as a", "which"], "entities" => [["Anarchism", "/Anarchism"], ["political philosophy", "/Political_philosophy"]]},
                  {"windows" => ["", "as a mass", "has"], "entities" => [["Anarchism", "/Anarchism"],["social movement", "/Social_movement"]]},
                 {"windows" => ["of", "as a", "has"], "entities" => [["anarchism", "/Anarchism"], ["social movement", "/Social_movement"]]}]

WINDOWS_SIZE_2 = [{"windows" => ["", "is often defined as a", "which holds"], "entities" => [["Anarchism", "/Anarchism"], ["political philosophy", "/Political_philosophy"]]},
                  {"windows" => ["", "as a mass", "has regularly"], "entities" => [["Anarchism", "/Anarchism"],["social movement", "/Social_movement"]]},
                  {"windows" => ["tendency of", "as a", "has been"], "entities" => [["anarchism", "/Anarchism"], ["social movement", "/Social_movement"]]}]

    # Example of dbpedia_relations:
    # {"/Anarchism"=>
    #  {"/Political_philosophy" => "/philosophy", "/Social_movement" => "/partOf"},
    #  "/Irving_Shulman"=> {"/Rebel_without_a_case" => "/wrote"}}


BLACKSMITH = Blacksmith.new(SENTENCES, "./spec/mocks/classes.gz")

CLASSES_MOCK = {"/Autism" => "/Disease", "/Animal_Farm" => "/Book", "/Aristotle" => "/Philosopher"}

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
    assert_equal(@blacksmith.isolate_ids_and_pure_text('<Anarchism/Anarchism> is often defined as a <political_philosophy/Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful'), ['<Anarchism/Anarchism>', 'is often defined as a', '<political_philosophy/Political_philosophy>', 'which holds the state to be undesirable, unnecessary, or harmful'])
    assert_equal(@blacksmith.isolate_ids_and_pure_text('<Anarchism/Anarchism> as a mass <social_movement/Social_movement> has regularly endured fluctuations in popularity'), ['<Anarchism/Anarchism>', 'as a mass', '<social_movement/Social_movement>', 'has regularly endured fluctuations in popularity'])
    assert_equal(@blacksmith.isolate_ids_and_pure_text("The so-called-<anarchism/Anarchism>'s father is <John/John>"), ["The so-called-", "<anarchism/Anarchism>", "'s father is", "<John/John>"])
  end

  def test_should_extract_windows
    [0,1,2].each do |i|
      assert_equal(@blacksmith.extract_windows(@sentences[i][0], 0), WINDOWS_SIZE_0[i])
    end

    [0,1,2].each do |i|
      assert_equal(@blacksmith.extract_windows(@sentences[i][0], 1), WINDOWS_SIZE_1[i])
    end

    [0,1,2].each do |i|
      assert_equal(@blacksmith.extract_windows(@sentences[i][0], 2), WINDOWS_SIZE_2[i])
    end
  end

  def test_shuold_extract_tags
    assert_equal(@blacksmith.extract_tags("is_VBZ often_RB defined_VBN as_IN a_DT"), ["VERB", "ADVERB", "VERB", "CONPREP", "ADVERB"])
    assert_equal(@blacksmith.extract_tags("as_IN a_DT mass_NN"), ["CONPREP", "ADVERB", "NOUN"])
    assert_equal(@blacksmith.extract_tags("as_IN a_DT"), ["CONPREP", "ADVERB"])
  end

  def test_should_apply_a_POS_tagger_on_the_inside_window
    assert_equal(@blacksmith.pos_tag_windows(WINDOWS_SIZE_2[0]), ["VERB", "ADVERB", "VERB", "CONPREP", "ADVERB"])
    assert_equal(@blacksmith.pos_tag_windows(WINDOWS_SIZE_2[1]), ["CONPREP", "ADVERB", "NOUN"])
    assert_equal(@blacksmith.pos_tag_windows(WINDOWS_SIZE_2[2]), ["CONPREP", "ADVERB"])
  end

  def test_should_filter_dependency_path
    assert_equal(@blacksmith.filter_dependency_path(["advmod(defined-4, often-3)", "amod(philosophy-8, political-7)", "auxpass(defined-4, is-2)", "det(philosophy-8, a-6)", "nsubjpass(defined-4, Anarchism-1)", "prep_as(defined-4, philosophy-8)", "root(ROOT-0, defined-4)"]), ["advmod(4, 3)", "amod(8, 7)", "auxpass(4, 2)", "det(8, 6)", "nsubjpass(4, 1)", "prep_as(4, 8)", "root(0, 4)"]);
    assert_equal(@blacksmith.filter_dependency_path(["amod(movement-6, mass-4)", "amod(movement-6, social-5)", "det(movement-6, a-3)", "prep_as(Anarchism-1, movement-6)", "root(ROOT-0, Anarchism-1)"]), ["amod(6, 4)", "amod(6, 5)", "det(6, 3)", "prep_as(1, 6)", "root(0, 1)"])
  end

  # collapsed dependency path
  def test_should_extract_dependency_path
    assert_equal(@blacksmith.dependency_path("Astronomer Edwin Hubble was born in Marshfield, Missourdi."), ["auxpass(born-5, was-4)", "nn(Hubble-3, Astronomer-1)", "nn(Hubble-3, Edwin-2)", "nn(Missourdi-9, Marshfield-7)", "nsubjpass(born-5, Hubble-3)", "prep_in(born-5, Missourdi-9)", "root(ROOT-0, born-5)"])
    assert_equal(@blacksmith.dependency_path("Anarchism is often defined as a political philosophy"), ["advmod(defined-4, often-3)", "amod(philosophy-8, political-7)", "auxpass(defined-4, is-2)", "det(philosophy-8, a-6)", "nsubjpass(defined-4, Anarchism-1)", "prep_as(defined-4, philosophy-8)", "root(ROOT-0, defined-4)"])
    assert_equal(@blacksmith.dependency_path("Anarchism as a mass social movement"), ["amod(movement-6, mass-4)", "amod(movement-6, social-5)", "det(movement-6, a-3)", "prep_as(Anarchism-1, movement-6)", "root(ROOT-0, Anarchism-1)"])
    assert_equal(@blacksmith.dependency_path("The central tendency of anarchism as a social movement has been"), ["amod(movement-9, social-8)", "amod(tendency-3, central-2)", "aux(been-11, has-10)", "det(movement-9, a-7)", "det(tendency-3, The-1)", "nsubj(been-11, tendency-3)", "prep_as(anarchism-5, movement-9)", "prep_of(tendency-3, anarchism-5)", "root(ROOT-0, been-11)"])
    assert_equal(@blacksmith.dependency_path("as a"), ["dep(as-1, a-2)", "root(ROOT-0, as-1)"])
    assert_equal(@blacksmith.dependency_path("as a social"), ["det(social-3, a-2)", "pobj(as-1, social-3)", "root(ROOT-0, as-1)"])
    assert_equal(@blacksmith.dependency_path("as a movement"), ["det(movement-3, a-2)", "pobj(as-1, movement-3)", "root(ROOT-0, as-1)"])
    assert_equal(@blacksmith.dependency_path("anarchism as a"), ["advmod(a-3, as-2)", "dobj(anarchism-1, a-3)", "root(ROOT-0, anarchism-1)"])
    assert_equal(@blacksmith.dependency_path("anarchism as a social"), ["det(social-4, a-3)", "prep_as(anarchism-1, social-4)", "root(ROOT-0, anarchism-1)"])
    assert_equal(@blacksmith.dependency_path("anarchism as a movement"), ["det(movement-4, a-3)", "prep_as(anarchism-1, movement-4)", "root(ROOT-0, anarchism-1)"])
    assert_equal(@blacksmith.dependency_path("of as a"), ["advmod(a-3, as-2)", "pobj(of-1, a-3)", "root(ROOT-0, of-1)"])
    assert_equal(@blacksmith.dependency_path("of as a social"), ["advmod(social-4, as-2)", "det(social-4, a-3)", "pobj(of-1, social-4)", "root(ROOT-0, of-1)"])
    assert_equal(@blacksmith.dependency_path("of as a movement"), ["cc(movement-4, as-2)", "det(movement-4, a-3)", "root(ROOT-0, movement-4)"])
  end

  # ONLY WINDOW SIZE 2!!!
  def test_should_apply_a_dependecy_parser_on_a_window
    assert_equal(@blacksmith.dependency_path_window(WINDOWS_SIZE_2[2]),
                 [
                  ["dep(1, 2)", "root(0, 1)"],
                  ["det(3, 2)", "pobj(1, 3)", "root(0, 1)"],
                  ["det(3, 2)", "pobj(1, 3)", "root(0, 1)"],
                  ["advmod(3, 2)", "dobj(1, 3)", "root(0, 1)"],
                  ["det(4, 3)", "prep_as(1, 4)", "root(0, 1)"],
                  ["det(4, 3)", "prep_as(1, 4)", "root(0, 1)"],
                  ["advmod(3, 2)", "pobj(1, 3)", "root(0, 1)"],
                  ["advmod(4, 2)", "det(4, 3)", "pobj(1, 4)", "root(0, 1)"],
                  ["cc(4, 2)", "det(4, 3)", "root(0, 4)"]
                 ])
  end

  def test_should_extract_entities_class
    assert_equal(@blacksmith.extract_classes(WINDOWS_SIZE_0[0]), ["owl:Thing", "owl:Thing"])
    assert_equal(@blacksmith.extract_classes({'entities' => [["", "/Autism"],["", "/Aristotle"]]}), ["/Disease", "/Philosopher"])
  end

  FEATURES_0 = ["is often defined as a",  #0
                ["VERB", "ADVERB", "VERB", "CONPREP", "ADVERB"], #0
                "",  #1
                [], #1
                "which", #2
                ["ADVERB"], #2
                "", #1
                [], #1
                "which holds", #3
                ["ADVERB", "VERB"], #3
                [["advmod(5, 4)", "advmod(3, 2)", "auxpass(3, 1)", "dobj(3, 5)", "root(0, 3)"], #0
                 ["advmod(3, 2)", "auxpass(3, 1)", "det(6, 5)", "nsubjpass(3, 6)", "prep(3, 4)", "root(0, 3)"], #1
                 ["advmod(3, 2)", "auxpass(3, 1)", "det(6, 5)", "prep_as(3, 6)", "root(0, 3)"], #2
                 ["advmod(6, 5)", "advmod(4, 3)", "auxpass(4, 2)", "dobj(4, 6)", "nsubjpass(4, 1)", "root(0, 4)"], #3
                 ["advmod(4, 3)", "auxpass(4, 2)", "det(7, 6)", "nsubjpass(4, 1)", "prep_as(4, 7)", "root(0, 4)"], #4
                 ["advmod(4, 3)", "auxpass(4, 2)", "det(7, 6)", "nsubjpass(4, 1)", "prep_as(4, 7)", "root(0, 4)"]], #4
                "owl:Thing", #0
                "owl:Thing", #0
                "/philosophy"]

  FEATURES_1 = ["as a mass", #4
                ["CONPREP", "ADVERB", "NOUN"], #4
                "", #1
                [], #1
                "has", #5
                ["VERB"], #5
                "", #1
                [], #1
                "has regularly", #6
                ["VERB", "ADVERB"], #6
                [["det(3, 2)", "pobj(1, 3)", "root(0, 1)"], #5
                 ["det(3, 2)", "npadvmod(4, 3)", "pobj(1, 4)", "root(0, 1)"], #6
                 ["amod(4, 3)", "det(4, 2)", "pobj(1, 4)", "root(0, 1)"], #7
                 ["det(4, 3)", "prep_as(1, 4)", "root(0, 1)"], #8
                 ["dep(5, 1)", "det(4, 3)", "prep_as(1, 4)", "root(0, 5)"], #9
                 ["amod(5, 4)", "det(5, 3)", "prep_as(1, 5)", "root(0, 1)"]], #1
                "owl:Thing",  #0
                "owl:Thing", #0
                "/partOf"]

  FEATURES_2 = ["as a", #7
                ["CONPREP", "ADVERB"], #7
                "of", #8
                ["CONPREP"], #8
                "has", #5
                ["VERB"], #5
                "tendency of", #9
                ["NOUN", "CONPREP"], #9
                "has been", #10
                ["VERB", "VERB"], #10
                [["dep(1, 2)", "root(0, 1)"], #11
                 ["det(3, 2)", "pobj(1, 3)", "root(0, 1)"], #5 
                 ["det(3, 2)", "pobj(1, 3)", "root(0, 1)"], #5 
                 ["advmod(3, 2)", "dobj(1, 3)", "root(0, 1)"], #12
                 ["det(4, 3)", "prep_as(1, 4)", "root(0, 1)"], #8 
                 ["det(4, 3)", "prep_as(1, 4)", "root(0, 1)"], #8 
                 ["advmod(3, 2)", "pobj(1, 3)", "root(0, 1)"], #13
                 ["advmod(4, 2)", "det(4, 3)", "pobj(1, 4)", "root(0, 1)"], #14
                 ["cc(4, 2)", "det(4, 3)", "root(0, 4)"]], #15
                "owl:Thing",  #0 
                "owl:Thing", #0 
                "/partOf"]

  def test_should_extract_features
    assert_equal(@blacksmith.extract_features(SENTENCES[0]), FEATURES_0)
    assert_equal(@blacksmith.extract_features(SENTENCES[1]), FEATURES_1)
    assert_equal(@blacksmith.extract_features(SENTENCES[2]), FEATURES_2)
  end

  def test_should_convert_features_to_ml
    assert_equal(@blacksmith.bow_sentences, {})
    assert_equal(@blacksmith.bow_classes, {})
    assert_equal(@blacksmith.bow_dp, {})
    assert_equal(@blacksmith.bow_pos, {})
    
    assert_equal(@blacksmith.convert_features_to_ml([FEATURES_0, FEATURES_1, FEATURES_2]), [[0,0,1,1,2,2,1,1,3,3,0,1,2,3,4,4,0,0, "/philosophy"], [4,4,1,1,5,5,1,1,6,6,5,6,7,8,9,10,0,0,"/partOf"],[7,7,8,8,5,5,9,9,10,10,11,5,5,12,8,8,13,14,15,0,0,"/partOf"]])
  end
end
