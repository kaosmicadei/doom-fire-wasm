(module
    ;; We need to set and export a memory space to hold the pixel data.
    (memory (export "memory") 1)

    ;; Pointer to the start of the image buffer in memory.
    (global $img_ptr i32 (i32.const 0))

    ;; NOTE: The image is stored in Row-major order.

    ;; Width and height of the image buffer.
    (global $img_width (mut i32) (i32.const 50))
    (global $img_height (mut i32) (i32.const 50))

    ;; WebAssembly doesn't have a built-in pseudo-random number generator so we 
    ;; will implement our own using the Xorshift algorithm.
    ;;
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
      i32.shr_u     ;; logical right shift, no sign preserving
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

    (func $set_image_size (param $width i32) (param $height i32)
      ;; set width
      local.get $width
      global.set $img_width

      ;; set height
      local.get $height
      global.set $img_height
    )

    ;; Initialise the bottom row of the image with the maximum value of 36.
    (func $fire_starter
      (local $row_idx i32)
      (local $col_idx i32)
      (local $pixel_idx i32)

      ;; Set the index of the bottom row.
      global.get $img_height
      i32.const 1
      i32.sub
      local.set $row_idx

      ;; Loop over all columns in the bottom row and set them to the maximum 
      ;; value of 36.
      i32.const 0
      local.set $col_idx

      ;; C-style loop over columns: 
      ;;     for (col_idx = 0; col_idx < img_width; col_idx++) {...}
      ;;
      (block $break
        (loop $continue
          ;; check if we have reached the end of the row.
          local.get $col_idx
          global.get $img_width
          i32.ge_s
          br_if $break

          ;; Calculate the pixel index for the current column in the bottom row.
          local.get $col_idx
          local.get $row_idx
          global.get $img_width
          i32.mul
          i32.add
          local.set $pixel_idx

          ;; Set the pixel at the calculated index to the maximum value of 36.
          i32.const 36
          global.get $img_ptr
          local.get $pixel_idx
          i32.add                ;; pixel address
          i32.store8

          ;; Increment the column index
          local.get $col_idx
          i32.const 1
          i32.add
          local.set $col_idx

          ;; Back to the start of the loop.
          br $continue
        )
      )
    )

    (func $spread_the_fire
      ;; Implementation for spreading the fire goes here.
    )

    (export "set_image_size" (func $set_image_size))
    (export "fire_starter" (func $fire_starter))
    (export "spread_the_fire" (func $spread_the_fire))
)
