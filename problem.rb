arr = [
  [ "a", "b", "c" ],
  [ "a", "b", "c" ],
  [ "a", "b", "c" ]
]

# returns count of occurences
def string_occurs(arr, word)
  occurences = 0
  arr.each_with_index do |inner_arr, row|
    inner_arr.each_with_index do |l, col|
      occurences += rec_string_occurences(arr, word, {}, x: col, y: row)
    end
  end
  occurences
end

# {0: 0, 1: 0, 2: 0}
# 0,0 1,0 1,1, 2,1
def rec_string_occurences(arr, word, path, y:, x:)
  puts "word: #{word}(#{word[0]}); checking (#{x},#{y}) #{arr.dig(x, y)}, path: #{path}"
  return 0 if x < 0 || y < 0
  return 0 if arr.dig(y, x) != word[0]
  return 0 if path[x] == y
  if arr.dig(y, x) == word
    puts "VALID PATH #{path} => #{word}"
    return 1
  end

  # found the A letter
  path[x] = y
  word = word[1..]

  [ [ 1, 0 ], [ -1, 0 ], [ 0, 1 ], [ 0, -1 ] ].map do |x_mov, y_mov|
    rec_string_occurences(arr, word, path.clone, x: x+x_mov, y: y+y_mov)
  end.sum
end

# puts string_occurs(arr, "abc")
puts string_occurs(arr, "abbc")
