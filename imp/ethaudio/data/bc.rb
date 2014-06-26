#!/bin/env ruby

ARGF.each_line do |line|
  line.each_byte do |var|
    case(var)
	  when 48 then  # 0 
	    print "0000"
	  when 49 then  # 1
	    print "0001"
	  when 50 then  # 2
	    print "0010"
	  when 51 then  # 3
	    print "0011"
	  when 52 then  # 4
	    print "0100"
	  when 53 then  # 5
	    print "0101"
	  when 54 then  # 6
	    print "0110"
	  when 55 then  # 7
	    print "0111"
	  when 56 then  # 8
	    print "1000"
	  when 57 then  # 9
	    print "1001"
	  when 65 then  # A
	    print "1010"
	  when 66 then  # B
	    print "1011"
	  when 67 then  # C
	    print "1100"
	  when 68 then  # D
	    print "1101"
	  when 69 then  # E 
	    print "1110"
	  when 70 then  # F
	    print "1111"
	  when 10 then
	    print "\n"
	end

  end
end
