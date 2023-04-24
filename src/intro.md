# Introduction

This book is a high-level explanation of the low-level details of WebAssembly components.

## Who is this book for?

This book is primarily intended for anyone who is working on implementation work of WebAssembly components such as low-level tooling that needs to interact directly with component binaries directly. Component authors and end users may find some information here useful (especially until resources more appropriate to those audiences are developed), but those audiences are not the focus of this book.

## What is this book not?

This book does not attempt to explain what WebAssembly is, how it compares to other technology, or what use cases it has. This book is more concerned with *how* components are created rather than why or their usage in any particular context.

This book is also not a formal specification or even the ground work for such a specification. While the hope is that this book's information is accurate, there is no attempt to eliminate all possible ambiguities or to provide formal definitions. Whenever possible, we will try to provide to link to resources where more formal definitions are being worked on.

## What do I need to get started?

To get the most out of this book, you'll need the following tools installed on your machine:
* [`wasm-tools`](https://github.com/bytecodealliance/wasm-tools)
