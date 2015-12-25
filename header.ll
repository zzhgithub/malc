; Start of malc header.ll

declare i32 @printf(i8*, ...)
declare i32 @exit(i32)
declare i8* @calloc(i32, i32)
declare void @free(i8*)

%mal_obj = type i64

; i32 - obj_type
; i32 - len (bytes/elements)
; i8* - points to data
%mal_obj_header_t = type { i32, i32, i8* }

define private %mal_obj @identity(%mal_obj %obj) {
  ret %mal_obj %obj
}

define private %mal_obj @bool_to_mal(i1 %cond) {
  br i1 %cond, label %IfEqual, label %IfUnequal
IfEqual:
  %1 = call %mal_obj @make_true()
  ret %mal_obj %1
IfUnequal:
  %2 = call %mal_obj @make_false()
  ret %mal_obj %2
}

define private %mal_obj @mal_integer_q(%mal_obj %obj) {
  %1 = and i64 %obj, 1
  %2 = icmp eq i64 %1, 1
  %3 = call %mal_obj @bool_to_mal(i1 %2)
  ret %mal_obj %3
}

define private %mal_obj @mal_nil_q(%mal_obj %obj) {
  %1 = icmp eq i64 %obj, 2
  %2 = call %mal_obj @bool_to_mal(i1 %1)
  ret %mal_obj %2
}

define private %mal_obj @mal_false_q(%mal_obj %obj) {
  %1 = icmp eq i64 %obj, 4
  %2 = call %mal_obj @bool_to_mal(i1 %1)
  ret %mal_obj %2
}

define private %mal_obj @mal_true_q(%mal_obj %obj) {
  %1 = icmp eq i64 %obj, 6
  %2 = call %mal_obj @bool_to_mal(i1 %1)
  ret %mal_obj %2
}

define private %mal_obj @mal_get_type(%mal_obj %obj) {
  %1 = icmp ugt i64 %obj, 6
  br i1 %1, label %IfObj, label %IfConst
IfObj:
  %2 = inttoptr %mal_obj %obj to %mal_obj_header_t*
  %3 = getelementptr %mal_obj_header_t* %2, i32 0, i32 0
  %4 = load i32* %3
  %5 = sext i32 %4 to i64
  %6 = call %mal_obj @make_integer(i64 %5)
  ret %mal_obj %6
IfConst:
  ret %mal_obj %obj
}

define private %mal_obj @mal_get_len(%mal_obj %obj) {
  %1 = inttoptr %mal_obj %obj to %mal_obj_header_t*
  %2 = getelementptr %mal_obj_header_t* %1, i32 0, i32 1
  %3 = load i32* %2
  %4 = sext i32 %3 to i64
  %5 = call %mal_obj @make_integer(i64 %4)
  ret %mal_obj %5
}

define private %mal_obj @mal_integer_equal_q(%mal_obj %a, %mal_obj %b) {
  %1 = icmp eq %mal_obj %a, %b
  %2 = call %mal_obj @bool_to_mal(i1 %1)
  ret %mal_obj %2
}

define private %mal_obj @make_integer(i64 %x) {
  %1 = shl i64 %x, 1
  %2 = or i64 %1, 1
  ret %mal_obj %2
}

define private i64 @mal_integer_to_raw(%mal_obj %obj) {
  %1 = ashr i64 %obj, 1
  ret i64 %1
}

define private %mal_obj @make_nil() {
  ret %mal_obj 2
}

define private %mal_obj @make_false() {
  ret %mal_obj 4
}

define private %mal_obj @make_true() {
  ret %mal_obj 6
}

define private %mal_obj_header_t* @alloc_obj_header() {
  %mal_obj_header_temp = getelementptr %mal_obj_header_t* null, i32 1
  %mal_obj_header_t_size = ptrtoint %mal_obj_header_t* %mal_obj_header_temp to i32
  %1 = call i8* @calloc(i32 1, i32 %mal_obj_header_t_size)
  %2 = bitcast i8* %1 to %mal_obj_header_t*
  ret %mal_obj_header_t* %2
}

define private %mal_obj @make_bytearray_obj(i32 %objtype, i32 %len_bytes, i8* %bytes) {
  %1 = call %mal_obj_header_t* @alloc_obj_header()
  %2 = getelementptr %mal_obj_header_t* %1, i32 0, i32 0
  store i32 %objtype, i32* %2
  %3 = getelementptr %mal_obj_header_t* %1, i32 0, i32 1
  store i32 %len_bytes, i32* %3

  ; %bytearrayptr = call i8* @calloc(i32 %len_bytes, i32 1)
  %4 = getelementptr %mal_obj_header_t* %1, i32 0, i32 2
  ;store i8* %bytearrayptr, i8** %4
  store i8* %bytes, i8** %4

  %new_obj = ptrtoint %mal_obj_header_t* %1 to %mal_obj
  ret %mal_obj %new_obj
}

define private %mal_obj @make_elementarray_obj(i32 %objtype, i32 %len_elements) {
  %1 = call %mal_obj_header_t* @alloc_obj_header()

  %2 = getelementptr %mal_obj_header_t* %1, i32 0, i32 0
  store i32 %objtype, i32* %2
  %3 = getelementptr %mal_obj_header_t* %1, i32 0, i32 1
  store i32 %len_elements, i32* %3

  %elementarrayptr = call i8* @calloc(i32 %len_elements, i32 8)
  %4 = getelementptr %mal_obj_header_t* %1, i32 0, i32 2
  store i8* %elementarrayptr, i8** %4

  %new_obj = ptrtoint %mal_obj_header_t* %1 to %mal_obj
  ret %mal_obj %new_obj
}

define private void @mal_set_elementarray_item(%mal_obj %obj, %mal_obj %item_index, %mal_obj %new_item) {
  %1 = inttoptr %mal_obj %obj to %mal_obj_header_t*
  %2 = getelementptr %mal_obj_header_t* %1, i32 0, i32 2
  %3 = bitcast i8** %2 to %mal_obj**
  %4 = load %mal_obj** %3
  %5 = call i64 @mal_integer_to_raw(%mal_obj %item_index)
  %6 = getelementptr %mal_obj* %4, i64 %5
  store %mal_obj %new_item, %mal_obj* %6
  ret void
}

define private %mal_obj @mal_get_elementarray_item(%mal_obj %obj, %mal_obj %item_index) {
  %1 = inttoptr %mal_obj %obj to %mal_obj_header_t*
  %2 = getelementptr %mal_obj_header_t* %1, i32 0, i32 2
  %3 = bitcast i8** %2 to %mal_obj**
  %4 = load %mal_obj** %3
  %5 = call i64 @mal_integer_to_raw(%mal_obj %item_index)
  %6 = getelementptr %mal_obj* %4, i64 %5
  %7 = load %mal_obj* %6
  ret %mal_obj %7
}

define private %mal_obj @mal_add(%mal_obj %a, %mal_obj %b) {
  %1 = call i64 @mal_integer_to_raw(%mal_obj %a)
  %2 = call i64 @mal_integer_to_raw(%mal_obj %b)
  %3 = add nsw i64 %1, %2
  %4 = call %mal_obj @make_integer(i64 %3)
  ret %mal_obj %4
}

define private %mal_obj @mal_sub(%mal_obj %a, %mal_obj %b) {
  %1 = call i64 @mal_integer_to_raw(%mal_obj %a)
  %2 = call i64 @mal_integer_to_raw(%mal_obj %b)
  %3 = sub nsw i64 %1, %2
  %4 = call %mal_obj @make_integer(i64 %3)
  ret %mal_obj %4
}

define private %mal_obj @mal_mul(%mal_obj %a, %mal_obj %b) {
  %1 = call i64 @mal_integer_to_raw(%mal_obj %a)
  %2 = call i64 @mal_integer_to_raw(%mal_obj %b)
  %3 = mul nsw i64 %1, %2
  %4 = call %mal_obj @make_integer(i64 %3)
  ret %mal_obj %4
}

define private %mal_obj @mal_div(%mal_obj %a, %mal_obj %b) {
  %1 = call i64 @mal_integer_to_raw(%mal_obj %a)
  %2 = call i64 @mal_integer_to_raw(%mal_obj %b)
  %3 = sdiv i64 %1, %2
  %4 = call %mal_obj @make_integer(i64 %3)
  ret %mal_obj %4
}

@printf_format_d = private unnamed_addr constant [5 x i8] c"%lld\00"

define private %mal_obj @mal_printnumber(%mal_obj %obj) {
  %1 = call i64 @mal_integer_to_raw(%mal_obj %obj)
  %2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([5 x i8]* @printf_format_d, i32 0, i32 0), i64 %1)
  %3 = call %mal_obj @make_nil()
  ret %mal_obj %3
}

@printf_format_s = private unnamed_addr constant [3 x i8] c"%s\00"

define private %mal_obj @mal_printbytearray(%mal_obj %obj) {
  %1 = inttoptr %mal_obj %obj to %mal_obj_header_t*
  %2 = getelementptr %mal_obj_header_t* %1, i32 0, i32 2
  %3 = load i8** %2
  %4 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([3 x i8]* @printf_format_s, i32 0, i32 0), i8* %3)
  %5 = call %mal_obj @make_nil()
  ret %mal_obj %5
}

@printf_newline = private unnamed_addr constant [2 x i8] c"\0A\00"

define private %mal_obj @mal_printnewline() {
  %1 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([2 x i8]* @printf_newline, i32 0, i32 0))
  %2 = call %mal_obj @make_nil()
  ret %mal_obj %2
}

; End of malc header.ll
