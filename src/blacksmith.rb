# -*- coding: utf-8 -*-
class Blacksmith
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

  def initialize(sentences)
    @sentences = sentences
  end

  
end
