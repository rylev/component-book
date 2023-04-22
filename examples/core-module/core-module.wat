(component
  (component
    (core module
      (import "console" "log" (func $log (param i32)))
      (func (export "logIt")
        i32.const 13
        call $log)
    )
  )
  (core module (func (export "two") (result f32) (f32.const 2)))
)