; Start of malc footer.ll

define i32 @main(i32 %argc, i8** %argv) #0 {
  %env = call %mal_obj @new_root_env()
  %1 = call %mal_obj @mal_prog_main(%mal_obj %env)
  ret i32 0
}

; End of malc footer.ll
