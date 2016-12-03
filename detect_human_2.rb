# -*- coding: utf-8 -*-
require 'csv'
require 'gnuplot'
require 'byebug'

# 抽出された各反射点からなるサイズ１のクラスタ群を生成する
# これらのクラスタの各ペアに対して，クラスタの重心間距離を算出し，クラスタ間距離が最小となるような２つのクラスタをマージ
# 最小クラスタ間距離が0.8以下になるまでマージ

class Cluster
  @@id_counter = 0
  attr_accessor :x, :y, :size, :id

  def initialize(x, y, size)
    # x, y is centroid of this cluster
    @x = x
    @y = y
    @size = size
    @id = @@id_counter
    @@id_counter += 1
  end

  # 重心を計算してマージ
  def self.merge(c1, c2)
    size = c1.size + c2.size
    x = (c1.x * c1.size + c2.x * c2.size) / size.to_f
    y = (c1.y * c1.size + c2.y * c2.size) / size.to_f
    Cluster.new(x, y, size)
  end

  def self.distance(c1, c2)
    Math.sqrt((c1.x - c2.x) * (c1.x - c2.x) + (c1.y - c2.y) * (c1.y - c2.y))
  end

  # 最近点対を分割統治法で求める
  def self.closest_pair(clusters)
    if clusters.size <= 1
      return nil, nil, Float::INFINITY
    end

    # 左右に分割して最近点対を求める
    l, r = clusters.each_slice(clusters.size / 2).to_a
    m = clusters[clusters.size / 2]
    c1, c2, d_min = closest_pair(l)
    rc1, rc2, r_min = closest_pair(r)
    if d_min > r_min
      c1 = rc1
      c2 = rc2
      d_min = r_min
    end

    # y座標でソート
    clusters.sort! { |a, b| a.y <=> b.y }
    b = []

    # 領域にまたがった最近点対を探す
    clusters.each do |c|
      next if (c.x - m.x).abs >= d_min
      b.reverse.each do |rb|
        next if c.y - rb.y >= d_min
        if d_min > distance(c, rb)
          d_min = distance(c, rb)
          c1 = c
          c2 = rb
        end
      end
      b.push(c)
    end
    # 最近点対， 距離を返す
    [c1, c2, d_min]
  end
end

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
    -300 <= last_x && last_x <= 3950 && 0 <= last_y && last_y <= 2100
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

def polar_to_xy(r, t)
  [r * Math.cos(t), r * Math.sin(t)]
end

# 1スキャンのクラスタを作成
def calc_clusters(data)
  min_distance = 0
  clusters = []

  # サイズ1のクラスタ群を生成
  data.each_with_index do |d, i|
    next if d.zero?
    x, y = polar_to_xy(d, (i - 180) * 0.25 * Math::PI / 180.0)
    clusters.push(Cluster.new(x, y, 1))
  end

  while min_distance < 800
    # 最近点対を求める
    c1, c2, min_distance = Cluster.closest_pair(clusters.sort { |a, b| a.x <=> b.x })
    break if c1.nil? || min_distance > 800
    # マージして最小距離を更新
    merged_cluster = Cluster.merge(c1, c2)
    clusters.select! { |c| c.id != c1.id && c.id != c2.id }
    clusters.push(merged_cluster)
  end
  clusters.delete_if { |cluster| cluster.size < 10 }
end

# 人の位置をプロット
def plot_humans(i, humans)
  Gnuplot.open do |gp|
    Gnuplot::Plot.new(gp) do |plot|
      if humans.empty?
        plot.data << Gnuplot::DataSet.new([[],[]])
      end
      print "#{i}: "
      humans.each do |h|
        print " #{h.last_x} #{h.last_y} #{h.moved?}"
        plot.data << Gnuplot::DataSet.new([[h.last_x], [h.last_y]]) do |ds|
          # 止まってるかどうかで色を変える
          if h.moved?
            ds.with = 'points ps 3 pt 7 lc rgb "black"'
          else
            ds.with = 'points ps 3 pt 7 lc rgb "red"'
          end
        end
      end
      # 縦横比と枠線追加
      plot.set 'size ratio 0.5'
      plot.set 'arrow 1 from 0,0 to 0,2100 nohead'
      plot.set 'arrow 2 from 3650,0 to 3650,2100 nohead'
      plot.set 'arrow 3 from 0,0 to 3650,0 nohead'
      plot.set 'arrow 4 from 0,2100 to 3650,2100 nohead'
      plot.xrange '[-1000:5000]'
      plot.yrange '[-500:2500]'
      # output
      plot.terminal 'png'
      plot.output File.expand_path("../#{File.basename(ARGV[0].to_s, File.extname(ARGV[0].to_s))}_2/#{format('%04d', i)}.png", __FILE__)
    end
  end
  puts ''
end

# 2つ前のスキャンを見て， 動いているか止まっているかを判定
def count_pedestrian(results)
  humans = []
  time_count = 0
  one_sec_results = []
  one_sec_humans = 0
  one_sec_moved = 0

  results.size.times do |i|
    humans.each { |human| human.detected = false }
    results[i].each do |cluster|
      used = false
      # 直前まで範囲にいた人について，その近くかどうかで同一人物か判定
      humans.each do |human|
        if human.push_if_near(cluster.x, cluster.y)
          used = true
          break
        end
      end
      # 新しい人を検出
      humans.push(Human.new(cluster.x, cluster.y)) unless used
    end

    # 検出できなかった人のミスカウントを追加，ミス判定を行う
    humans.each { |human| human.missed += 1 unless human.detected }
    humans.delete_if(&:miss?)

    plot_humans(i, humans)

    # シーケンス処理
    # 一人でも動いている人がいたらそのシーケンスは動いている
    humans.each do |human|
      next unless human.in_area?
      one_sec_humans += 1
      unless human.moved?
        one_sec_moved += 1
      end
    end

    time_count += 1
    # 1scan/25ms = 40scan / s
    if time_count == 40
      one_sec_results.push([(one_sec_humans / 40).round, (one_sec_moved / 40).round])
      one_sec_humans = 0
      one_sec_moved = 0
      time_count = 0
    end
  end

  # このシーケンスの結果
  one_sec_results.size.times do |i|
    puts "#{i} #{one_sec_results[i][0]} #{one_sec_results[i][1]}"
  end
end

# ------------------ main -----------------------------------
# CSV読みこみ→ クラスタリング→ 人について追加処理

table = CSV.table(ARGV[0].to_s).by_col
results = []

table.each do |col|
  data = col[1][5..1085]
  next if data[1].nil?

  # データをクラスタリングしてresultsにプッシュ
  results.push(calc_clusters(data))
end

# クラスタに対して，人かどうか判定
count_pedestrian(results)

