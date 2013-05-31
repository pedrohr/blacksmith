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

  
end
