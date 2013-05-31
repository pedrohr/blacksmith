# -*- coding: utf-8 -*-
require 'pp'
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

  def isolate_ids_and_pure_text(sentence)
    vec = []
    to_push = true

    return [""] if sentence.empty?

    sentence.split(" ").each do |token|
      if (token.include?("</"))
        
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
      if token.include?("</")
        unless first_entity
          first_entity = true
        else
          second_entity = true
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

    return [left.strip, inside_window.strip, right.strip]
  end
end
