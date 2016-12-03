# -*- coding: utf-8 -*-
module EventDetection
  class Human
    attr_accessor :id, :missed, :history, :detected
    @@id_counter = 0
    def initialize(x, y)
      @history = [[x, y]]
      @missed = 0
      @detected = true
      @id = @@id_counter
      @@id_counter += 1
    end

    def miss?
      @missed > 3
    end

    def near?(x, y)
      distance(x, y) < 150 ? true : false
    end

    def moved?
      return false if @history.size < 3
      distance(@history[-3][0], @history[-3][1]) > 25 ? true : false
    end

    def in_area?
      0 <= last_x && last_x <= 2000 && -5000 <= last_y && last_y <= -1000
    end

    def push_if_near(x, y)
      if near?(x, y)
        @history.push([x, y])
        @missed = 0
        @detected = true
        return true
      end
      false
    end

    def last_x
      @history[-1][0]
    end

    def last_y
      @history[-1][1]
    end

    def distance(x1, y1)
      Math.sqrt((last_x - x1) * (last_x - x1) + (last_y - y1) * (last_y - y1))
    end
  end

  def self.detect(sequences)
    humans = []
    seq_result = 0
    sequences.size.times do |i|
      humans.each { |human| human.detected = false }
      sequences[i].each do |data|
        used = false
        humans.each do |human|
          if human.push_if_near(data[0], data[1])
            used = true
            break
          end
        end
        humans.push(Human.new(data[0], data[1])) unless used
      end

      humans.each { |h| h.missed += 1 unless h.detected }
      humans.delete_if(&:miss?)

      humans.each do |h|
        next unless h.in_area?
        seq_result += h.moved? ? 1 : 2
      end
    end
    event = seq_result / sequences.size.to_f
    if event >= 1.5
      puts 2
    elsif event >= 0.5
      puts 1
    else
      puts 0
    end
  end
end

# 一秒ごとにイベント検知の結果を出力
sequences = []
while s = gets
  t, n = s.split.map(&:to_i)
  data = []
  n.times do
    data.push(gets.split.map(&:to_f))
  end
  sequences.push(data)
  # 40scan毎にイベントの判定
  if sequences.size >= 40
    print "#{t} "
    EventDetection.detect(sequences)
    sequences = []
  end
end
