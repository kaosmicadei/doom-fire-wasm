(module
    ;; We need to set and export a memory space to hold the pixel data.
    (memory (export "memory") 1)

    ;; WebAssembly doesn't have a built-in pseudo-random number generator so we 
    ;; will implement our own using the Xorshift algorithm.

    ;; Initialize the RNG state with a non-zero value.
    (global $rng_state (mut i32) (i32.const 127))

    ;; Xorshift algorithm:
    ;;     x = rng_state
    ;;     x ^= x << 13
    ;;     x ^= x >> 17
    ;;     x ^= x << 5
    ;;     rng_state = x
    (func $rand (result i32)
      (local $x i32)
      global.get $rng_state
      local.tee $x            ;; copy without popping

      ;; x = x ^ (x << 13)
      local.get $x
      i32.const 13
      i32.shl        ;; left shift
      i32.xor
      local.tee $x

      ;; x = x ^ (x >>> 17)  (logical right shift)
      local.get $x
      i32.const 17
      i32.shr_u     ;; logical right shift
      i32.xor
      local.tee $x

      ;; x = x ^ (x << 5)
      local.get $x
      i32.const 5
      i32.shl
      i32.xor
      local.tee $x

      ;; rng_state = x
      local.get $x
      global.set $rng_state

      ;; There is still one value left on the stack that will be used to return 
      ;; from the function.
    )
)