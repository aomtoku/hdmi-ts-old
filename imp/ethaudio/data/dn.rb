#!/bin/env ruby

ARGF.each_line do |line|
  cnt = 0
  line.each_byte do |var|
    cnt += 1
	print var.chr
	if cnt == 11 || cnt == 22 || cnt == 29 then
		printf " "
	end
  end
end
