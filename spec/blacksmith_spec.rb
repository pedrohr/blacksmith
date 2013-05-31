# -*- coding: utf-8 -*-
require 'test/unit'
require './src/blacksmith.rb'

class BlacksmitTest < Test::Unit::TestCase
  def setup
    @sentences = [['</Anarchism> is often defined as a </Political_philosophy> which holds the state to be undesirable, unnecessary, or harmful', '/philosophy'],
     ['</Anarchism> as a mass </Social_movement> has regularly endured fluctuations in popularity', '/partOf'],
     ["The central tendency of </Anarchism> as a </Social_movement> has been represented by anarcho-communism and anarcho-syndicalism, with individualist anarchism being primarily a literary phenomenon which nevertheless did have an impact on the bigger currents and individualists have also participated in large anarchist organizations", '/partOf']]

    # Example of dbpedia_relations:
    # {"/Anarchism"=>
    #  {"/Political_philosophy" => "/philosophy", "/Social_movement" => "/partOf"},
    #  "/Irving_Shulman"=> {"/Rebel_without_a_case" => "/wrote"}}

    @blacksmith = Blacksmith.new(@sentences)
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
end
