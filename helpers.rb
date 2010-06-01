# Helpers
class Array
  def average
    self.inject(0) { |mem, var| mem+var }.to_f / self.length
  end

  def most_common
    counts = Hash.new(0)
    self.each { |i| counts[i] += 1 }
    sorted = counts.sort { |a,b| a[1]<=>b[1] }
    highest_count = sorted.last[1]
    return nil if highest_count == 0
    sorted.select { |x| x[1] == highest_count }.collect { |x| x[0] }
  end
end