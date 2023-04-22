(component
  (core module $numbers
    (func (export "one") (result i32) (i32.const 1))
    (func (export "two") (result i32) (i32.const 2))
  )
  (core module $doSomething
    (func (import "theNumbers" "myNumber") (result i32))
  )
  (core instance $firstInstance (instantiate $numbers))

  ;; Here's where things get interesting...
  (core func $two (alias core export $firstInstance "two"))
  (core instance $secondInstance (instantiate $doSomething
    (with "theNumbers" (instance
      (export "myNumber" (func $two))
    ))
  ))
)