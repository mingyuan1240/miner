#
#repeat(10) {
#tuple { 
#    int32(10); int64(20); cond(ref(0) != 10, 11, 12); switch(ref(1), [220, true], [10, false] ) 
#}
#}

p %w{1 2 3}
