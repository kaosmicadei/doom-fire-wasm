(module
    ;; We need to set and export a memory space to hold the pixel data.
    (memory (export "memory") 1)  ;; 1 page ≡ 64KiB

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

    (func $set_fire_size (param $width i32) (param $height i32)
      ;; set width
      local.get $width
      global.set $img_width

      ;; set height
      local.get $height
      global.set $img_height
    )

    ;; Initialise the bottom row of the image with the maximum value of 36.
    (func $fire_starter
      (local $total_pixels i32)
      (local $pixel_idx i32)

      ;; Compute the total number of pixels in the image.
      global.get $img_width
      global.get $img_height
      i32.mul
      local.set $total_pixels

      ;; The last row starts that (img_height - 1) * img_width.
      global.get $img_width
      global.get $img_height
      i32.const 1
      i32.sub
      i32.mul
      local.set $pixel_idx

      ;; Loop over all columns in the bottom row and set them to the maximum 
      ;; value of 36.
      ;;
      ;; C-style loop over columns: 
      ;;     for (pixel_idx = 0; pixel_idx < total_pixels; pixel_idx++) {...}
      ;;
      (block $break
        (loop $continue
          ;; check if we have reached the end of the row.
          local.get $pixel_idx
          local.get $total_pixels
          i32.lt_s
          i32.eqz
          br_if $break

          ;; Set the pixel to the maximum value of 36.
          global.get $img_ptr
          local.get $pixel_idx
          i32.add                ;; pixel address
          i32.const 36
          i32.store8

          ;; Increment the pixel index
          local.get $pixel_idx
          i32.const 1
          i32.add
          local.set $pixel_idx

          ;; Back to the start of the loop.
          br $continue
        )
      )
    )

    (func $spread_the_fire 
      (local $total_pixels i32)
      (local $pixel_idx i32)

      (local $value i32)
      
      ;; Calculate the total number of pixels in the image.
      ;; However, we must leave the bottom row out.
      global.get $img_width
      global.get $img_height
      i32.const 1
      i32.sub
      i32.mul
      local.set $total_pixels

      i32.const 0
      local.set $pixel_idx

      (loop $pixels
        ;; get the value of the pixel one row below (pixel_idx + img_width)
        global.get $img_ptr
        local.get $pixel_idx
        global.get $img_width
        i32.add
        i32.add
        i32.load8_u  ;; push img_ptr[pixel_idx + img_width] onto the stack
        
        ;; Compute the decay by subtracting a random integer between 0 and 3
        ;; (exclusive)
        call $rand
        i32.const 3
        i32.rem_u       ;; rand % 3
        i32.sub
        local.tee $value

        ;; The value cannot be less than 0.
        i32.const 0
        
        ;; condition
        i32.const 0
        local.get $value
        i32.lt_s

        select
        local.set $value

        ;; store the value in the current pixel
        global.get $img_ptr
        local.get $pixel_idx
        i32.add
        local.get $value
        i32.store8

        ;; increment the pixel index
        local.get $pixel_idx
        i32.const 1
        i32.add
        local.tee $pixel_idx

        ;; check if we have reached the total number of pixels
        local.get $total_pixels
        i32.lt_s
        br_if $pixels
      )
    )


    (func $img_addr (result i32)
      global.get $img_ptr
    )

    (export "img_addr" (func $img_addr))
    (export "set_fire_size" (func $set_fire_size))
    (export "fire_starter" (func $fire_starter))
    (export "spread_the_fire" (func $spread_the_fire))
)
