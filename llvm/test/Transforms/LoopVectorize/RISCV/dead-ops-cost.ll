; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; RUN: opt -p loop-vectorize -mtriple riscv64-linux-gnu -mattr=+v,+f -S %s | FileCheck %s

target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; Test with a dead load in the loop, from
; https://github.com/llvm/llvm-project/issues/99701
define void @dead_load(ptr %p, i16 %start) {
; CHECK-LABEL: define void @dead_load(
; CHECK-SAME: ptr [[P:%.*]], i16 [[START:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[START_EXT:%.*]] = sext i16 [[START]] to i64
; CHECK-NEXT:    [[SMAX:%.*]] = call i64 @llvm.smax.i64(i64 [[START_EXT]], i64 111)
; CHECK-NEXT:    [[TMP0:%.*]] = sub i64 [[SMAX]], [[START_EXT]]
; CHECK-NEXT:    [[UMIN:%.*]] = call i64 @llvm.umin.i64(i64 [[TMP0]], i64 1)
; CHECK-NEXT:    [[TMP1:%.*]] = sub i64 [[SMAX]], [[UMIN]]
; CHECK-NEXT:    [[TMP2:%.*]] = sub i64 [[TMP1]], [[START_EXT]]
; CHECK-NEXT:    [[TMP3:%.*]] = udiv i64 [[TMP2]], 3
; CHECK-NEXT:    [[TMP4:%.*]] = add i64 [[UMIN]], [[TMP3]]
; CHECK-NEXT:    [[TMP5:%.*]] = add i64 [[TMP4]], 1
; CHECK-NEXT:    [[TMP6:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP7:%.*]] = mul i64 [[TMP6]], 8
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ule i64 [[TMP5]], [[TMP7]]
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label %[[SCALAR_PH:.*]], label %[[VECTOR_PH:.*]]
; CHECK:       [[VECTOR_PH]]:
; CHECK-NEXT:    [[TMP8:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP9:%.*]] = mul i64 [[TMP8]], 8
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP5]], [[TMP9]]
; CHECK-NEXT:    [[TMP10:%.*]] = icmp eq i64 [[N_MOD_VF]], 0
; CHECK-NEXT:    [[TMP11:%.*]] = select i1 [[TMP10]], i64 [[TMP9]], i64 [[N_MOD_VF]]
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP5]], [[TMP11]]
; CHECK-NEXT:    [[TMP12:%.*]] = mul i64 [[N_VEC]], 3
; CHECK-NEXT:    [[IND_END:%.*]] = add i64 [[START_EXT]], [[TMP12]]
; CHECK-NEXT:    [[TMP13:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP14:%.*]] = mul i64 [[TMP13]], 8
; CHECK-NEXT:    [[DOTSPLATINSERT:%.*]] = insertelement <vscale x 8 x i64> poison, i64 [[START_EXT]], i64 0
; CHECK-NEXT:    [[DOTSPLAT:%.*]] = shufflevector <vscale x 8 x i64> [[DOTSPLATINSERT]], <vscale x 8 x i64> poison, <vscale x 8 x i32> zeroinitializer
; CHECK-NEXT:    [[TMP15:%.*]] = call <vscale x 8 x i64> @llvm.stepvector.nxv8i64()
; CHECK-NEXT:    [[TMP16:%.*]] = add <vscale x 8 x i64> [[TMP15]], zeroinitializer
; CHECK-NEXT:    [[TMP17:%.*]] = mul <vscale x 8 x i64> [[TMP16]], shufflevector (<vscale x 8 x i64> insertelement (<vscale x 8 x i64> poison, i64 3, i64 0), <vscale x 8 x i64> poison, <vscale x 8 x i32> zeroinitializer)
; CHECK-NEXT:    [[INDUCTION:%.*]] = add <vscale x 8 x i64> [[DOTSPLAT]], [[TMP17]]
; CHECK-NEXT:    [[TMP18:%.*]] = call i64 @llvm.vscale.i64()
; CHECK-NEXT:    [[TMP19:%.*]] = mul i64 [[TMP18]], 8
; CHECK-NEXT:    [[TMP20:%.*]] = mul i64 3, [[TMP19]]
; CHECK-NEXT:    [[DOTSPLATINSERT1:%.*]] = insertelement <vscale x 8 x i64> poison, i64 [[TMP20]], i64 0
; CHECK-NEXT:    [[DOTSPLAT2:%.*]] = shufflevector <vscale x 8 x i64> [[DOTSPLATINSERT1]], <vscale x 8 x i64> poison, <vscale x 8 x i32> zeroinitializer
; CHECK-NEXT:    br label %[[VECTOR_BODY:.*]]
; CHECK:       [[VECTOR_BODY]]:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, %[[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], %[[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_IND:%.*]] = phi <vscale x 8 x i64> [ [[INDUCTION]], %[[VECTOR_PH]] ], [ [[VEC_IND_NEXT:%.*]], %[[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP21:%.*]] = getelementptr i16, ptr [[P]], <vscale x 8 x i64> [[VEC_IND]]
; CHECK-NEXT:    call void @llvm.masked.scatter.nxv8i16.nxv8p0(<vscale x 8 x i16> zeroinitializer, <vscale x 8 x ptr> [[TMP21]], i32 2, <vscale x 8 x i1> shufflevector (<vscale x 8 x i1> insertelement (<vscale x 8 x i1> poison, i1 true, i64 0), <vscale x 8 x i1> poison, <vscale x 8 x i32> zeroinitializer))
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i64 [[INDEX]], [[TMP14]]
; CHECK-NEXT:    [[VEC_IND_NEXT]] = add <vscale x 8 x i64> [[VEC_IND]], [[DOTSPLAT2]]
; CHECK-NEXT:    [[TMP22:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP22]], label %[[MIDDLE_BLOCK:.*]], label %[[VECTOR_BODY]], !llvm.loop [[LOOP0:![0-9]+]]
; CHECK:       [[MIDDLE_BLOCK]]:
; CHECK-NEXT:    br label %[[SCALAR_PH]]
; CHECK:       [[SCALAR_PH]]:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i64 [ [[IND_END]], %[[MIDDLE_BLOCK]] ], [ [[START_EXT]], %[[ENTRY]] ]
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ [[BC_RESUME_VAL]], %[[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr i16, ptr [[P]], i64 [[IV]]
; CHECK-NEXT:    store i16 0, ptr [[GEP]], align 2
; CHECK-NEXT:    [[L:%.*]] = load i16, ptr [[GEP]], align 2
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 3
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i64 [[IV]], 111
; CHECK-NEXT:    br i1 [[CMP]], label %[[LOOP]], label %[[EXIT:.*]], !llvm.loop [[LOOP3:![0-9]+]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    ret void
;
entry:
  %start.ext = sext i16 %start to i64
  br label %loop

loop:
  %iv = phi i64 [ %start.ext, %entry ], [ %iv.next, %loop ]
  %gep = getelementptr i16, ptr %p, i64 %iv
  store i16 0, ptr %gep, align 2
  %l = load i16, ptr %gep, align 2
  %iv.next = add i64 %iv, 3
  %cmp = icmp slt i64 %iv, 111
  br i1 %cmp, label %loop, label %exit

exit:
  ret void
}

; Test case for https://github.com/llvm/llvm-project/issues/100464.
; Loop with a live-out %l and scalar epilogue required due to an interleave
; group. As the scalar epilogue is required the live-out is fed from the scalar
; epilogue and dead in the vector loop.
define i8 @dead_live_out_due_to_scalar_epilogue_required(ptr %src, ptr %dst) {
; CHECK-LABEL: define i8 @dead_live_out_due_to_scalar_epilogue_required(
; CHECK-SAME: ptr [[SRC:%.*]], ptr [[DST:%.*]]) #[[ATTR0]] {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[TMP0:%.*]] = call i32 @llvm.vscale.i32()
; CHECK-NEXT:    [[TMP1:%.*]] = mul i32 [[TMP0]], 4
; CHECK-NEXT:    [[TMP2:%.*]] = call i32 @llvm.umax.i32(i32 8, i32 [[TMP1]])
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ule i32 252, [[TMP2]]
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label %[[SCALAR_PH:.*]], label %[[VECTOR_MEMCHECK:.*]]
; CHECK:       [[VECTOR_MEMCHECK]]:
; CHECK-NEXT:    [[SCEVGEP:%.*]] = getelementptr i8, ptr [[DST]], i64 1005
; CHECK-NEXT:    [[SCEVGEP1:%.*]] = getelementptr i8, ptr [[SRC]], i64 1005
; CHECK-NEXT:    [[BOUND0:%.*]] = icmp ult ptr [[DST]], [[SCEVGEP1]]
; CHECK-NEXT:    [[BOUND1:%.*]] = icmp ult ptr [[SRC]], [[SCEVGEP]]
; CHECK-NEXT:    [[FOUND_CONFLICT:%.*]] = and i1 [[BOUND0]], [[BOUND1]]
; CHECK-NEXT:    br i1 [[FOUND_CONFLICT]], label %[[SCALAR_PH]], label %[[VECTOR_PH:.*]]
; CHECK:       [[VECTOR_PH]]:
; CHECK-NEXT:    [[TMP3:%.*]] = call i32 @llvm.vscale.i32()
; CHECK-NEXT:    [[TMP4:%.*]] = mul i32 [[TMP3]], 4
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i32 252, [[TMP4]]
; CHECK-NEXT:    [[TMP5:%.*]] = icmp eq i32 [[N_MOD_VF]], 0
; CHECK-NEXT:    [[TMP6:%.*]] = select i1 [[TMP5]], i32 [[TMP4]], i32 [[N_MOD_VF]]
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i32 252, [[TMP6]]
; CHECK-NEXT:    [[IND_END:%.*]] = mul i32 [[N_VEC]], 4
; CHECK-NEXT:    [[TMP7:%.*]] = call i32 @llvm.vscale.i32()
; CHECK-NEXT:    [[TMP8:%.*]] = mul i32 [[TMP7]], 4
; CHECK-NEXT:    [[TMP9:%.*]] = call <vscale x 4 x i32> @llvm.stepvector.nxv4i32()
; CHECK-NEXT:    [[TMP10:%.*]] = add <vscale x 4 x i32> [[TMP9]], zeroinitializer
; CHECK-NEXT:    [[TMP11:%.*]] = mul <vscale x 4 x i32> [[TMP10]], shufflevector (<vscale x 4 x i32> insertelement (<vscale x 4 x i32> poison, i32 4, i64 0), <vscale x 4 x i32> poison, <vscale x 4 x i32> zeroinitializer)
; CHECK-NEXT:    [[INDUCTION:%.*]] = add <vscale x 4 x i32> zeroinitializer, [[TMP11]]
; CHECK-NEXT:    [[TMP12:%.*]] = call i32 @llvm.vscale.i32()
; CHECK-NEXT:    [[TMP13:%.*]] = mul i32 [[TMP12]], 4
; CHECK-NEXT:    [[TMP14:%.*]] = mul i32 4, [[TMP13]]
; CHECK-NEXT:    [[DOTSPLATINSERT:%.*]] = insertelement <vscale x 4 x i32> poison, i32 [[TMP14]], i64 0
; CHECK-NEXT:    [[DOTSPLAT:%.*]] = shufflevector <vscale x 4 x i32> [[DOTSPLATINSERT]], <vscale x 4 x i32> poison, <vscale x 4 x i32> zeroinitializer
; CHECK-NEXT:    br label %[[VECTOR_BODY:.*]]
; CHECK:       [[VECTOR_BODY]]:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i32 [ 0, %[[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], %[[VECTOR_BODY]] ]
; CHECK-NEXT:    [[VEC_IND:%.*]] = phi <vscale x 4 x i32> [ [[INDUCTION]], %[[VECTOR_PH]] ], [ [[VEC_IND_NEXT:%.*]], %[[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP15:%.*]] = sext <vscale x 4 x i32> [[VEC_IND]] to <vscale x 4 x i64>
; CHECK-NEXT:    [[TMP16:%.*]] = getelementptr i8, ptr [[DST]], <vscale x 4 x i64> [[TMP15]]
; CHECK-NEXT:    call void @llvm.masked.scatter.nxv4i8.nxv4p0(<vscale x 4 x i8> zeroinitializer, <vscale x 4 x ptr> [[TMP16]], i32 1, <vscale x 4 x i1> shufflevector (<vscale x 4 x i1> insertelement (<vscale x 4 x i1> poison, i1 true, i64 0), <vscale x 4 x i1> poison, <vscale x 4 x i32> zeroinitializer)), !alias.scope [[META4:![0-9]+]], !noalias [[META7:![0-9]+]]
; CHECK-NEXT:    [[INDEX_NEXT]] = add nuw i32 [[INDEX]], [[TMP8]]
; CHECK-NEXT:    [[VEC_IND_NEXT]] = add <vscale x 4 x i32> [[VEC_IND]], [[DOTSPLAT]]
; CHECK-NEXT:    [[TMP17:%.*]] = icmp eq i32 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP17]], label %[[MIDDLE_BLOCK:.*]], label %[[VECTOR_BODY]], !llvm.loop [[LOOP9:![0-9]+]]
; CHECK:       [[MIDDLE_BLOCK]]:
; CHECK-NEXT:    br label %[[SCALAR_PH]]
; CHECK:       [[SCALAR_PH]]:
; CHECK-NEXT:    [[BC_RESUME_VAL:%.*]] = phi i32 [ [[IND_END]], %[[MIDDLE_BLOCK]] ], [ 0, %[[ENTRY]] ], [ 0, %[[VECTOR_MEMCHECK]] ]
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ [[BC_RESUME_VAL]], %[[SCALAR_PH]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[IDXPROM:%.*]] = sext i32 [[IV]] to i64
; CHECK-NEXT:    [[GEP_SRC:%.*]] = getelementptr i8, ptr [[SRC]], i64 [[IDXPROM]]
; CHECK-NEXT:    [[L:%.*]] = load i8, ptr [[GEP_SRC]], align 1
; CHECK-NEXT:    [[GEP_DST:%.*]] = getelementptr i8, ptr [[DST]], i64 [[IDXPROM]]
; CHECK-NEXT:    store i8 0, ptr [[GEP_DST]], align 1
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 4
; CHECK-NEXT:    [[CMP:%.*]] = icmp ult i32 [[IV]], 1001
; CHECK-NEXT:    br i1 [[CMP]], label %[[LOOP]], label %[[EXIT:.*]], !llvm.loop [[LOOP10:![0-9]+]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    [[R:%.*]] = phi i8 [ [[L]], %[[LOOP]] ]
; CHECK-NEXT:    ret i8 [[R]]
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %idxprom = sext i32 %iv to i64
  %gep.src = getelementptr i8, ptr %src, i64 %idxprom
  %l = load i8, ptr %gep.src, align 1
  %gep.dst = getelementptr i8, ptr %dst, i64 %idxprom
  store i8 0, ptr %gep.dst, align 1
  %iv.next = add i32 %iv, 4
  %cmp = icmp ult i32 %iv, 1001
  br i1 %cmp, label %loop, label %exit

exit:
  %r = phi i8 [ %l, %loop ]
  ret i8 %r
}


;.
; CHECK: [[LOOP0]] = distinct !{[[LOOP0]], [[META1:![0-9]+]], [[META2:![0-9]+]]}
; CHECK: [[META1]] = !{!"llvm.loop.isvectorized", i32 1}
; CHECK: [[META2]] = !{!"llvm.loop.unroll.runtime.disable"}
; CHECK: [[LOOP3]] = distinct !{[[LOOP3]], [[META2]], [[META1]]}
; CHECK: [[META4]] = !{[[META5:![0-9]+]]}
; CHECK: [[META5]] = distinct !{[[META5]], [[META6:![0-9]+]]}
; CHECK: [[META6]] = distinct !{[[META6]], !"LVerDomain"}
; CHECK: [[META7]] = !{[[META8:![0-9]+]]}
; CHECK: [[META8]] = distinct !{[[META8]], [[META6]]}
; CHECK: [[LOOP9]] = distinct !{[[LOOP9]], [[META1]], [[META2]]}
; CHECK: [[LOOP10]] = distinct !{[[LOOP10]], [[META1]]}
;.
