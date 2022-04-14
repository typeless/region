# Region
*Region* is a region-based, composable memory allocation library

It can be used as
- A memory leak detector
- A memory usage profiler
- A memory management scheme

## Features
1. Region-based, scoped, automatic heap management.
2. Scoped memory usage profiling.
3. Scoped memory leak checking.
4. Application-level controllability and observability of heap allocations.
5. Composable, policy-based, off-the-shelf heap allocators.
6. Extensible by third-party libraries and application code.
7. Minimal dependency. (It depends only on the lib `sys` shipped by the compiler)

## Regions
A region provides a 'scratchpad'-like execution context, where heap allocations
can be managed by a user-speficifed allocator.

### APIs

#### For user applications
```
	generic enter		: (a : @a#, f : (-> @t) -> @t) :: layer @a
```
`enter` takes a pointer to an allocator (composed of heap layers) and a closure.
All heap allocations happening within the closure will be *handled* by the allocator.

```
	generic escape		: (f : (-> @t) -> @t)
```
`escape` takes a closure. All allocations within the closure will *escape* from the current region.
That is, the escaped allocations will be handled by the outer region.

Then you can use `std.alloc`, `std.mk`, `std.bytealloc`, `std.bytefree` and friends as usual.
All heap allocations will be handled by the enclosing region automatically.

#### For heap layer implementers
Please refer to the `layer` directory for references. In particular, the `bypass` layer can be used as a template.
You can also implement a layer externally as a third-pary library.

### An example
```
use std
use region
use layer
use sys

const main = {
        var b : layer.stats(layer.chunk(layer.batch(layer.check(layer.stats(layer.mmap))), byte[4096]))
        b = region.init()

        var xs : int[:]
        xs = std.slalloc(0)

        std.put("outside region xs: {}@{}\n", xs, &xs)

        xs = region.enter(&b, {

                var ys = std.slalloc(0)
                for var i = 0; i < 5; i++
                        std.slpush(&ys, i)
                ;;

                xs = region.escape({
                        -> std.sljoin(&xs, ys)
                })

                var zs = std.slalloc(0)
                for var i = 0; i < 5; i++
                        std.slpush(&zs, i+i*10)
                ;;

                xs = region.escape({
                        -> std.sljoin(&xs, zs)
                })

                -> xs
        })

        std.put("outside region xs: {}@{}\n", xs, &xs)
        std.put("{}\n", b)
}
```
You can find the code at `examples/append.myr`

## Layers
A layer is a type implemting the trait **layer**.
```
trait layer @a =
	init		: (-> @a)
	deinit		: (a : @a# -> void)
	get		: (a : @a#, sz : sys.size -> byte#)
	put		: (a : @a#, p : byte#, sz : sys.size -> void)
;;
```
Layers are composable.
A customized allocator can be composed by combining one or more layers.
Trait functions **get** and **put** allocate and deallocate memory blocks from the allocator.

**init** and **deinit** are, as you would expect, the constructor and destructor.

Heap layers is inspired by https://github.com/emeryberger/Heap-Layers

### Top layers
At the moment we provide three system layers: `sbrk`, `mmap`, and `std`.
There is the `bonwick` layer as well, which is ported from the `std` library.

### Primitive layers
#### Chunk Layer
`type chunk(@super, @size) :: region.layer @super`

The layer is a bump allocator that returns memory blocks from available chunks.
When all chunks are used up, it requests more chunks from the underlying layer.

`@size` is a type that represents a user-specified chunk size, which equals to `sizeof(@size)`.

#### Batch Layer
`type batch(@super) :: region.layer @super`

All allocations passed through the layer are booked for deallocations in batch.

#### Stats Layer
`type stats(@super) :: region.layer @super`

Records the counts and sizes of allocations/deallocations.

#### Check Layer
`type check(@super) :: region.layer, region.gauge @super`

Check if every allocation is deallocated. If not, abort the program.

## Gauge
```
trait gauge @g =
	gauge		: (a : @g# -> (sys.size, sys.size, sys.size, sys.size, sys.size))
;;
```
A Layer gauge is a trait that provides a view for querying the information of a layer.
(Note that this trait is likely to be changed in the future.)


## Build
```
$ make
$ make test
$ make bench
$ make clean
```

## Run examples
```
$ make
$ ./obj/examples/append
$ ./obj/examples/json/jsonparse
```

## Tests
Tests? What tests?

Joking aside, the modified `rt` has been set up with a region at program startup already.
With this customization, it does, at least, pass the tests in `libstd` and `libjson`.

## TODO
1. Benchmark
2. A heap layer to check use-after-free bug.
3. Heap layers implementing various composable lock schemes on other layers.
5. Heap layers specifying alignments.
6. Heap layers used in multithread environments.
7. Heap layers providing 'auto-zeroing' heap variants.
8. Scoped tracing GC (Boehm?) and reference counting?
9. Extend the region design pattern to resources other than memory.
10. Coalescable and freelist layers.
11. Slab and buddy layers.
12. Customizations of `rt` for platforms other than Linux.
