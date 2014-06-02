#!/env/ruby 

re = /^(\d+)/

max = 0
min = 0

data = Array.new

n = 0
sum = 0

ARGF.each_line do |line|
  begin
    if re.match(line)
		cycl = $1.to_i
		data.push cycl

		sum += (cycl * 10)
		n += 1
	end
  end
end


data.each do |line| 
  begin
    printf "%d %d\n", line, (line * 10)
  end
end

printf "\n\nStatics Information\n"
printf "max/avg/min %d/%d/%d ns\n", data.max * 10, sum/n, data.min * 10
