# -*- coding: utf-8 -*-
# 抽出された各反射点からなるサイズ１のクラスタ群を生成する
# これらのクラスタの各ペアに対して，クラスタの重心間距離を算出し，クラスタ間距離が最小となるような２つのクラスタをマージ
# 最小クラスタ間距離が0.8以下になるまでマージ
# 判定
require 'pry'
module Clustering
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
      return nil, nil, Float::INFINITY if clusters.size <= 1

      # 左右に分割して最近点対を求める
      l, r = clusters.each_slice(clusters.size / 2).to_a
      m = clusters[clusters.size / 2]
      c1, c2, d_min = closest_pair(l)
      rc1, rc2, r_min = closest_pair(r)
      c1, c2, d_min = rc1, rc2, r_min if d_min > r_min

      # y座標でソート
      clusters.sort! { |a, b| a.y <=> b.y }
      b = []

      # 領域にまたがった最近点対を探す
      clusters.each do |c|
        next if (c.x - m.x).abs >= d_min
        b.reverse.each do |rb|
          next if d_min <= c.y - rb.y || d_min <= distance(c, rb)
          c1, c2, d_min = c, rb, distance(c, rb)
        end
        b.push(c)
      end
      # 最近点対， 距離を返す
      [c1, c2, d_min]
    end
  end

  # 1スキャンのクラスタを作成
  def self.calc_clusters(data)
    min_distance = 0
    clusters = []

    # サイズ1のクラスタ群を生成
    data.each do |d|
      next if d[0].zero? && d[1].zero?
      clusters.push(Cluster.new(d[0], d[1], 1))
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
end

# スキャン毎にクラスタリングした結果を出力
bg_data = []
_ = gets
1081.times { bg_data.push(gets.split.map(&:to_i)) }
while t = gets
  data = []
  1081.times do |i|
    x, y = gets.split.map(&:to_i)
    if (x - bg_data[i][0]).abs > 10 || (y - bg_data[i][1]).abs > 10
      data.push([x, y])
    else
      data.push([0, 0])
    end
  end
  clusters = Clustering.calc_clusters(data)

  # time & size
  puts "#{t.to_i} #{clusters.size}"
  # position
  clusters.each do |c|
    puts "#{c.x} #{c.y}"
  end
end
