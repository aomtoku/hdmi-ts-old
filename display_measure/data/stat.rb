#!/env/ruby 

re = /^(\d+)/

max = 0
min = 0

data = Array.new

n = 0
sum = 0.0
sqsum = 0.0

ARGF.each_line do |line|
  begin
    if re.match(line)
		cycl = $1.to_i
		data.push cycl

		sum += (cycl / 100)
		n += 1

		sqsum += (cycl / 100)**2

	end
  end
end

mean = Float(sum) / n
var = Float(sqsum) / n - mean**2
stddev = Math.sqrt(var)

r = n / 2 
if n % 2 != 0
  median = data[r] 
else
  median = (data[r - 1] + data[r])/2
end

  median = Float(median) / 100

data.each do |line| 
  begin
    printf "%d %d\n", line, (line / 100)
  end
end

printf "\n\nStatics Information\n"
printf "max/mean/median/stddev/min %.1f/%.1f/%.1f/%.1f/%.1f ns\n", data.max / 100, mean, median, stddev, data.min / 100
