#!/bin/env ruby

#p "11111111".to_i(2) 

ARGF.each_line do |line|
 sp = line.split(" ")
 if sp.size == 4 then 
   s1 = sp[0].to_i(2)
   s2 = sp[1].to_i(2)
   s3 = sp[2].to_i(2)
   s4 = sp[3].to_i(2)
   printf "%d %d %d %d\n", s1, s2, s3, s4
 end
end
