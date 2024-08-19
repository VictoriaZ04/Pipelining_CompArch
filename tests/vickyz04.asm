@0
// Basic testing with no hazards

// test 0 : Testing movl test 0 
movl r0, #48 // print 0
movl r0, #10 // print \n

// test 1 : Testing sub
movl r1, #50 
movl r2, #1                        
sub r0, r1, r2 // print 1                   
movl r0, #10 // print \n                            // mem 10

// test 2 : Testing movh
movl r1, #50
movh r1, #1
movl r2, #0
movh r2, #1
sub r0, r1, r2 // print 2                           // mem 20             
movl r0, #10 // print \n                    
                                
// test 3 : Testing st -- self modifies code -- no hazard  
// writes the instruction 8330 -- movl r0, #64
movl r1, #64 // Setting write address               
movl r2, #48 // writing instruction pt1
movh r2, #131 // writing instruction pt2    

movl r10, #0 // buffer                              // mem 30
movl r10, #0 // buffer                              
movl r10, #0 // buffer 
movl r10, #0 // buffer 
movl r10, #0 // buffer                      
movl r10, #0 // buffer                              // mem 40
movl r10, #0 // buffer                              
movl r10, #0 // buffer 

st r2, r1 // rewriting the instruction

movl r10, #0 // buffer                      
movl r10, #0 // buffer                              // mem 50
movl r10, #0 // buffer                              
movl r10, #0 // buffer 
movl r10, #0 // buffer          
movl r10, #0 // buffer                      
movl r10, #0 // buffer                              // mem 60
movl r10, #0 // buffer                              
end
movl r0, #10 // print \n 

// test 4 : Testing ld
movl r1, #255 // Setting write address               
movl r2, #52 // value to be written             // mem 70

movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer 
movl r10, #0 // buffer 
movl r10, #0 // buffer                               // mem 80
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer 

st r2, r1 // writing to mem

movl r10, #0 // buffer                               // mem 90
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer 
movl r10, #0 // buffer          
movl r10, #0 // buffer                               // mem 100
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer 
ld r0, r1 // print 4
movl r0, #10 // print \n 

// test 5: Jz jump
movl r11, #234                                       // mem 110
movl r1, #150    // jump location                    

movl r10, #0 // buffer                               
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              // mem 120
movl r10, #0 // buffer                                       
movl r10, #0 // buffer                               
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer

jz r1, r0 // should jump                            // mem 130
                            
movl r10, #0 // buffer                                                            
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer 
movl r10, #0 // buffer                              // mem 140
movl r10, #0 // buffer                              
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer

movl r0, #120 // print x -- should not print

movl r0, #53 // print 5 -- should jump to here      // mem 150
movl r0, #10 // print \n 

// test 6: jz no jump
jz r11, r1 // should not jump

movl r10, #0 // buffer                                                            
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              // mem 160
movl r10, #0 // buffer                              
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer

movl r0, #54 // print 6           

// test 7: Jnz jump
movl r1, #209    // jump location                   // mem 170                   

movl r10, #0 // buffer                               
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer                            
movl r10, #0 // buffer                              // mem 180         
movl r10, #0 // buffer                               
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer

jnz r1, r1 // should jump                            
                            
movl r10, #0 // buffer                              // mem 190                                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              
movl r10, #0 // buffer 
movl r10, #0 // buffer                              
movl r10, #0 // buffer                              // mem 200
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer

movl r0, #120 // print x -- should not print

movl r0, #55 // print 5 -- should jump to here      
movl r0, #10 // print \n                            // mem 210

// test 7: jz no jump
jnz r11, r0 // should not jump

movl r10, #0 // buffer                                                            
movl r10, #0 // buffer                              
movl r10, #0 // buffer    
                          
movl r10, #0 // buffer                              // mem 220                              
movl r10, #0 // buffer                             
movl r10, #0 // buffer                              
movl r10, #0 // buffer                                                    
movl r10, #0 // buffer

movl r0, #56 // print 6                             // mem 230                          

end                                                
movl r0, #120
end