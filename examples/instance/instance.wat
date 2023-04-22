(component
  (core module $numbers
    (func (export "one") (result i32) (i32.const 1))
  )
  (core module $doSomething
    (func (import "myNamespace" "one") (result i32))
  )
  (core instance $firstInstance (instantiate $numbers))
  (core instance $secondInstance (instantiate $doSomething (with "myNamespace" (instance $firstInstance))))
)