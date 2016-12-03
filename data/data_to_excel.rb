ts = []
data = []
xy = []
while t = gets
  ts.push("time")
  ts.push(t.chomp)
  xy.push("x y")
  data.push([])
  1081.times do |i|
    x, y = gets.split.map(&:to_i)
    data[-1].push([x, y])
  end
end

puts ts.join(' ')
puts xy.join(' ')
data[0].size.times do |i|
  data.size.times do |j|
    print "#{data[j][i][0]} #{data[j][i][1]} "
  end
  puts ""
end
