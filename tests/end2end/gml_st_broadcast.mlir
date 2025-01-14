// RUN: mlir-hlo-opt %s
// TODO(b/249781306): Re-enable the test.
// not_r_u_n:   --gml-st-pipeline="tile-sizes=1,1,1 lower-to-loops"
// not_r_u_n: mlir-cpu-runner -e main -entry-point-result=void \
// not_r_u_n:   -shared-libs=%mlir_lib_dir/libmlir_c_runner_utils%shlibext,%mlir_lib_dir/libmlir_runner_utils%shlibext | \
// not_r_u_n: FileCheck %s

// TODO(frgossen): Add test for tiled broadcast when it works.

func.func @dynamic_bcast(%arg : tensor<1x2x?xf32>, %shape : tensor<3xindex>)
    -> tensor<?x?x?xf32> {
  %0 = "mhlo.dynamic_broadcast_in_dim"(%arg, %shape)
      {broadcast_dimensions = dense<[0, 1, 2]> : tensor<3xi64>}
      : (tensor<1x2x?xf32>, tensor<3xindex>) -> tensor<?x?x?xf32>
  func.return %0 : tensor<?x?x?xf32>
}

func.func @main() {
  %test_arg = arith.constant dense<[[[1.2, 3.4, 5.6], [7.8, 9.1, 2.3]]]>
      : tensor<1x2x3xf32>
  %test_arg_ = tensor.cast %test_arg : tensor<1x2x3xf32> to tensor<1x2x?xf32>
  %test_shape = arith.constant dense<[4, 2, 3]> : tensor<3xindex>

  %test_res = func.call @dynamic_bcast(%test_arg_, %test_shape)
      : (tensor<1x2x?xf32>, tensor<3xindex>) -> tensor<?x?x?xf32>

  // CHECK: rank = 3
  // CHECK: offset = 0
  // CHECK: sizes = [4, 2, 3]
  // CHECK: strides = [6, 3, 1]
  // CHECK:   1.2, 3.4, 5.6
  // CHECK:   7.8, 9.1, 2.3
  // CHECK:   1.2, 3.4, 5.6
  // CHECK:   7.8, 9.1, 2.3
  // CHECK:   1.2, 3.4, 5.6
  // CHECK:   7.8, 9.1, 2.3
  // CHECK:   1.2, 3.4, 5.6
  // CHECK:   7.8, 9.1, 2.3
  %test_res_unranked = tensor.cast %test_res
      : tensor<?x?x?xf32> to tensor<*xf32>
  func.call @printMemrefF32(%test_res_unranked) : (tensor<*xf32>) -> ()

  func.return
}

func.func private @printMemrefF32(%ptr : tensor<*xf32>)
