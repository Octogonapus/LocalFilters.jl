#
# basics.jl --
#
# Basic methods for local filters.
#
#------------------------------------------------------------------------------
#
# This file is part of the `LocalFilters.jl` package licensed under the MIT
# "Expat" License.
#
# Copyright (C) 2017-2018, Éric Thiébaut.
#

# Extend `CartesianIndices` and, maybe, `CartesianRange` which have been
# imported from where they are.
@static if USE_CARTESIAN_RANGE
    CartesianRange(B::Neighborhood) = CartesianRange(limits(B)...)
    convert(::Type{CartesianRange}, B::Neighborhood) = CartesianRange(B)
    function convert(::Type{CartesianRange{CartesianIndex{N}}},
                     B::Neighborhood{N}) where N
        return CartesianRange(B)
    end
end
CartesianIndices(B::Neighborhood) =
    CartesianIndices(map((i,j) -> i:j,
                         Tuple(initialindex(B)), Tuple(finalindex(B))))
convert(::Type{CartesianIndices}, B::Neighborhood) =
    CartesianIndices(B)
convert(::Type{CartesianIndices{N}}, B::Neighborhood{N}) where N =
    CartesianIndices(B)

# Default implementation of common methods.
ndims(::Neighborhood{N}) where {N} = N
length(B::Neighborhood) = prod(size(B))
size(B::Neighborhood) =
    map(_length, Tuple(initialindex(B)), Tuple(finalindex(B)))
size(B::Neighborhood, d) = _length(initialindex(B)[d], finalindex(B)[d])
axes(B::Neighborhood) =
    map((i,j) -> i:j, Tuple(initialindex(B)), Tuple(finalindex(B)))
axes(B::Neighborhood, d) = (initialindex(B)[d]:finalindex(B)[d])
getindex(B::Neighborhood, inds::Union{Integer,CartesianIndex}...) =
    getindex(B, CartesianIndex(inds...))
setindex!(B::Neighborhood, val, inds::Union{Integer,CartesianIndex}...) =
    setindex!(B, val, CartesianIndex(inds...))

@inline _length(start::Int, stop::Int) = max(Int(stop) - Int(start) + 1, 0)

"""
```julia
defaultstart(A) -> I::CartesianIndex
```

yields the initial (multi-dimensional) index of a rectangular region which has
the same size as the array `A` but whose origin (that is, index
`zero(CartesianIndex{N})`) is at the geometrical center of the region (with the
same conventions as [`fftshift`](@ref)).

"""
defaultstart(A::AbstractArray) =
    CartesianIndex(map(rng -> -(Int(length(rng)) >> 1), axes(A)))

"""

```
initialindex(B) -> Imin::CartesianIndex{N}
finalindex(B)   -> Imax::CartesianIndex{N}
```

respectively yield the initial and final multi-dimensional index for indexing
the Cartesian region defined by `B`.  A Cartesian region defines a rectangular
set of indices whose edges are aligned with the indexing axes.

Compared to similar methods [`firstindex`](@ref), [`lastindex()`](@ref),
[`first()`](@ref) and [`last()`](@ref), the returned value is always an
instance of `CartesianIndex{N}` with `N` the number of dimensions.

Any multi-dimensional index `I::CartesianIndex{N}` is in the Cartesian region
defined `B` if and only if `Imin ≤ I ≤ Imax`.

Also see: [`limits`](@ref).
"""
initialindex(B::Neighborhood) = B.start
finalindex(B::Neighborhood) = B.stop

initialindex(R::CartesianIndices) = first(R)
finalindex(R::CartesianIndices) = last(R)

initialindex(A::AbstractArray) = initialindex(axes(A))
finalindex(A::AbstractArray) = finalindex(axes(A))

initialindex(inds::UnitIndexRanges{N}) where {N} =
    CartesianIndex(map(first, inds))
finalindex(inds::UnitIndexRanges{N}) where {N} =
     CartesianIndex(map(last, inds))

initialindex(inds::NTuple{2,CartesianIndex{N}}) where {N} = inds[1]
finalindex(inds::NTuple{2,CartesianIndex{N}}) where {N} = inds[2]

@static if USE_CARTESIAN_RANGE
    # For compatibility with Julia ≤ 0.6
    initialindex(R::CartesianRange) = first(R)
    finalindex(R::CartesianRange) = last(R)
end

"""

```julia
limits(T::DataType) -> typemin(T), typemax(T)
```

yields the infimum and supremum of a type `T`.


```julia
limits(B) -> Imin, Imax
```

yields the corners (as a tuple of 2 `CartesianIndex`) of the Cartesian
region defined by `B`.

Also see: [`initialindex`](@ref) and [`finalindex`](@ref).

"""
limits(::Type{T}) where {T} = typemin(T), typemax(T)
limits(A::AbstractArray) = limits(axes(A)) # provides a slight optimization?
limits(B::Neighborhood) = initialindex(B), finalindex(B)
limits(R::CartesianIndices) = initialindex(R), finalindex(R)
limits(inds::UnitIndexRanges{N}) where {N} =
    initialindex(inds), finalindex(inds)
limits(inds::NTuple{2,CartesianIndex{N}}) where {N} = inds
@static if USE_CARTESIAN_RANGE
    limits(R::CartesianRange) = initialindex(R), finalindex(R)
end

"""

```julia
cartesianregion(args...) -> R
```

yields the rectangular region (as an instance of `CartesianIndices` or
`CartesianRange` depending on Julia version) specified by the arguments which
can be:

* an abstract array whose axes define the region (see [`axes`](@ref));

* a list of unit range indices and/or indices along each dimension;

* the corners of the bounding box, say `start` and `stop`, specified as two
  instances of `CartesianIndex`;

* a neighborhood (see [`Neighborhood`](@ref));

* an instance of `CartesianIndices` or `CartesianRange`.

This method is a workaround to deal with optimization issues between different
versions of Julia.  In recent Julia versions (≥ 0.7),
`cartesianregion(args...)` yields an instance of `CartesianIndices`; while in
Julia version 0.6, `cartesianregion(args...)` yields a `CartesianRange` which
appears to be faster than `CartesianIndices` as provided by `Compat`.

See also: [`initialindex`](@ref), [`finalindex`](@ref) and [`limits`](@ref).

"""
cartesianregion(B::Neighborhood) =
    cartesianregion(initialindex(B), finalindex(B))
cartesianregion(A::AbstractArray) = cartesianregion(axes(A))
# The most critical version of `cartesianregion` is the one which takes the
# first and last indices of the region and which is inlined.
@static if USE_CARTESIAN_RANGE
    # Favor CartesianRange.
    cartesianregion(R::CartesianRange) = R
    cartesianregion(R::CartesianIndices) = cartesianregion(R.indices)
    @inline function cartesianregion(start::CartesianIndex{N},
                                     stop::CartesianIndex{N}) where N
	return CartesianRange(start, stop)
    end
    cartesianregion(inds::UnitIndexRanges{N}) where N =
        CartesianRange(initialindex(inds), finalindex(inds))
else
    # Favor CartesianIndices.
    cartesianregion(R::CartesianIndices) = R
    @inline function cartesianregion(start::CartesianIndex{N},
                                     stop::CartesianIndex{N}) where N
	return CartesianIndices(map((i,j) -> i:j, Tuple(start), Tuple(stop)))
    end
    cartesianregion(inds::UnitIndexRanges{N}) where N =
        CartesianIndices(inds)
end

#------------------------------------------------------------------------------

# To implement variants and out-of-place versions, we define conversion rules
# to convert various types of arguments into a neighborhood suitable with the
# source (e.g., of given rank `N`).

convert(::Type{Neighborhood}, x) = Neighborhood(x)
convert(::Type{Neighborhood}, x::Neighborhood) = x
convert(::Type{Neighborhood{N}}, x) where {N} = Neighborhood{N}(x)
convert(::Type{Neighborhood{N}}, x::Neighborhood{N}) where {N} = x

convert(::Type{RectangularBox}, x) = RectangularBox(x)
convert(::Type{RectangularBox}, x::RectangularBox) = x
convert(::Type{RectangularBox{N}}, x) where {N} = RectangularBox{N}(x)
convert(::Type{RectangularBox{N}}, x::RectangularBox{N}) where {N} = x

convert(::Type{Kernel}, x) = Kernel(x)
convert(::Type{Kernel}, x::Kernel) = x
convert(::Type{Kernel{T}}, x) where {T} = Kernel{T}(x)
convert(::Type{Kernel{T}}, x::Kernel{T}) where {T} = x
convert(::Type{Kernel{T,N}}, x) where {T,N} = Kernel{T,N}(x)
convert(::Type{Kernel{T,N}}, x::Kernel{T,N}) where {T,N} = x


# Outer Neighborhood constructors.

Neighborhood(B::Neighborhood) = B
Neighborhood{N}(B::Neighborhood{N}) where {N} = B

Neighborhood(A::AbstractArray) = Kernel(A)
Neighborhood{N}(A::AbstractArray{T,N}) where {T,N} = Kernel(A)

Neighborhood(dims::Integer...) = RectangularBox(dims)
Neighborhood(dims::Dimensions{N}) where {N} = RectangularBox(dims)
Neighborhood{N}(dims::Dimensions{N}) where {N} = RectangularBox(dims)
Neighborhood{N}(dim::Integer) where {N} = RectangularBox{N}(dim)

Neighborhood(rngs::UnitIndexRange...) = RectangularBox(rngs)
Neighborhood(rngs::UnitIndexRanges{N}) where {N} = RectangularBox(rngs)
Neighborhood{N}(rngs::UnitIndexRanges{N}) where {N} = RectangularBox(rngs)
Neighborhood{N}(rng::UnitIndexRange) where {N} = RectangularBox{N}(rng)

Neighborhood(R::CartesianIndices) = RectangularBox(R)
Neighborhood{N}(R::CartesianIndices{N}) where {N} = RectangularBox(R)

@static if USE_CARTESIAN_RANGE
    Neighborhood(R::CartesianRange) = RectangularBox(R)
    Neighborhood{N}(R::CartesianRange{CartesianIndex{N}}) where {N} =
        RectangularBox(R)
end

#------------------------------------------------------------------------------
#
# METHODS FOR RECTANGULAR BOXES
# =============================
#
# A RectangularBox is a neighborhood defined by a rectangular (Cartesian) box,
# possibly off-centered.
#

_range(dim::Integer) = _range(Int(dim))

function _range(dim::Int)
    dim ≥ 1 ||
        throw(ArgumentError("neighborhood dimension(s) must be at least one"))
    imin = -(dim >> 1)
    imax = dim + imin - 1
    return imin:imax
end

RectangularBox(B::RectangularBox) = B
RectangularBox{N}(B::RectangularBox{N}) where {N} = B

RectangularBox(dim::Integer) = RectangularBox{1}(dim)
RectangularBox{N}(dim::Integer) where {N} = RectangularBox{N}(_range(dim))

RectangularBox(dims::Integer...) = RectangularBox(dims)
RectangularBox{N}(dims::Integer...) where {N} = RectangularBox{N}(dims)

RectangularBox(dims::Dimensions{N}) where {N} =
    RectangularBox(map(_range, dims))
RectangularBox{N}(dims::Dimensions{N}) where {N} = RectangularBox(dims)

function RectangularBox{N}(rng::UnitIndexRange) where {N}
    imin = Int(first(rng))
    imax = Int(last(rng))
    Imin = CartesianIndex(ntuple(d -> imin, Val(N)))
    Imax = CartesianIndex(ntuple(d -> imax, Val(N)))
    return RectangularBox{N}(Imin, Imax)
end

RectangularBox(rngs::UnitIndexRange...) = RectangularBox(rngs)
RectangularBox{N}(rngs::UnitIndexRange...) where {N} = RectangularBox{N}(rngs)

function RectangularBox(rngs::UnitIndexRanges{N}) where {N}
    I1 = CartesianIndex(map(r -> Int(first(r)), rngs))
    I2 = CartesianIndex(map(r -> Int(last(r)), rngs))
    return RectangularBox{N}(I1, I2)
end

RectangularBox{N}(rngs::UnitIndexRanges{N}) where {N} =
    RectangularBox(rngs)

RectangularBox(R::CartesianIndices) =
    RectangularBox(initialindex(R), finalindex(R))
RectangularBox{N}(R::CartesianIndices{N}) where {N} =
    RectangularBox(initialindex(R), finalindex(R))

@static if USE_CARTESIAN_RANGE
    RectangularBox(R::CartesianRange) =
        RectangularBox(initialindex(R), finalindex(R))
    RectangularBox{N}(R::CartesianRange{CartesianIndex{N}}) where {N} =
        RectangularBox(initialindex(R), finalindex(R))
end

#------------------------------------------------------------------------------
# METHODS FOR KERNELS

eltype(B::Kernel{T,N}) where {T,N} = T
length(B::Kernel) = length(coefs(B))
size(B::Kernel) = size(coefs(B))
size(B::Kernel, d) = size(coefs(B), d)
getindex(B::Kernel, I::CartesianIndex) = getindex(coefs(B), I + offset(B))
setindex!(B::Kernel, val, I::CartesianIndex) =
    setindex!(coefs(B), val, I + offset(B))

"""

`LocalFilters.coefs(B)` yields the array of coefficients embedded in
kernel `B`.

"""
coefs(B::Kernel) = B.coefs

"""

`LocalFilters.offset(B)` yields the index offset of the array of coefficients
embedded in kernel `B`.   That is, `B[k] ≡ coefs(B)[k + offset(B)]`.

"""
offset(B::Kernel) = B.offset

# This method is to call the inner constructor.
Kernel(C::AbstractArray{T,N}, off::CartesianIndex{N}) where {T,N} =
    Kernel{T,N,typeof(C)}(C,off)

# Methods to convert other neighborhoods.  When type of coefficients is
# converted, boolean to floating-point yields `0` or `-Inf` so as to have a
# consistent *flat* structuring element.

Kernel(B::RectangularBox) = Kernel(ones(Bool, size(B)), initialindex(B))
Kernel(::Type{Bool}, B::RectangularBox) = Kernel(B)
Kernel(K::Kernel) = K
Kernel(::Type{T}, K::Kernel{T,N}) where {T,N} = K
Kernel(::Type{Bool}, K::Kernel{Bool,N}) where {N} = K
Kernel(::Type{T}, K::Kernel{<:Any,N}) where {T,N} =
    Kernel{T,N,Array{T,N}}(convert(Array{T,N}, coefs(K)), initialindex(K))
Kernel(::Type{T}, K::Kernel{Bool,N}) where {T<:AbstractFloat,N} =
    Kernel((zero(T), -T(Inf)), coefs(K), initialindex(K))

# Methods to wrap an array into a kernel (call copy if you do not want to
# share).

Kernel(A::AbstractArray) =
    Kernel(A, defaultstart(A))

Kernel(::Type{T}, A::AbstractArray) where {T} =
    Kernel(T, A, defaultstart(A))

Kernel(A::AbstractArray{T,N}, inds::Dimensions{N}) where {T,N} =
    Kernel(A, CartesianIndex(inds))

Kernel(::Type{T}, A::AbstractArray{<:Any,N},
       inds::Dimensions{N}) where {T,N} =
    Kernel(T, A, CartesianIndex(inds))

Kernel(::Type{T}, A::AbstractArray{T,N}, I::CartesianIndex{N}) where {T,N} =
    Kernel(A, I)

Kernel(::Type{T}, A::AbstractArray{<:Any,N}, I::CartesianIndex{N}) where {T,N} =
    Kernel(convert(Array{T,N}, A), I)

Kernel(::Type{T}, A::AbstractArray{Bool,N},
       I::CartesianIndex{N} = defaultstart(A)) where {T<:AbstractFloat,N} =
    Kernel((zero(T), -T(Inf)), A, I)

Kernel(A::AbstractArray, inds::UnitIndexRange...) =
    Kernel(A, inds)

function Kernel(A::AbstractArray{T,N}, bnds::CartesianRegion{N}) where {T,N}
    # Bounds for indexing the kernel.
    kmin, kmax = limits(bnds)

    # Bounds for indexing the array of coeffcients.
    jmin, jmax = limits(A)

    # Check size is identical for all dimensions.
    all(d -> (jmax[d] - jmin[d]) == (kmax[d] - kmin[d]), 1:N) ||
        throw(DimensionMismatch("dimensions must be the same"))

    # Make a kernel with the correct initial index.
    return Kernel(A, kmin)
end

# Methods to convert other neighborhoods.  Beware that booleans mean something
# specific, i.e. the result is a so-called *flat* structuring element
# when a kernel whose coefficients are boolean is converted to some
# floating-point type.

# Make a flat structuring element from a boolean mask.
function Kernel(tup::Tuple{T,T},
                msk::AbstractArray{Bool,N},
                start::CartesianIndex{N} = defaultstart(msk)) where {T,N}
    arr = similar(Array{T}, axes(msk))
    vtrue, vfalse = tup[1], tup[2]
    @inbounds for i in eachindex(arr, msk)
        arr[i] = msk[i] ? vtrue : vfalse
    end
    Kernel(arr, start)
end

Kernel(tup::Tuple{T,T}, B::Kernel{Bool,N}) where {T,N} =
    Kernel(tup, coefs(B), initialindex(B))

# Make a kernel from a function and anything suitable to define a Cartesian
# region.  The element type of the kernel coefficients can be imposed.
function Kernel(::Type{T}, f::Function, bnds::CartesianRegion{N}) where {T,N}
    kmin, kmax = limits(bnds)
    W = Array{T,N}(undef, map(_length, Tuple(kmin), Tuple(kmax)))
    offs = initialindex(W) - kmin
    @inbounds for i in cartesianregion(bnds)
        W[i + offs] = f(i)
    end
    return Kernel{T,N,Array{T,N}}(W, kmin)
end

# Idem but element type of the kernel if automatically guessed.
Kernel(f::Function, bnds::CartesianRegion) =
    Kernel(map(f, cartesianregion(bnds)), initialindex(bnds))

# Conversion of the data type of the kernel coefficients.
for F in (:Float64, :Float32, :Float16)
    @eval begin
        Base.$F(K::Kernel{$F,N}) where {N} = K
        Base.$F(K::Kernel{T,N}) where {T,N} = Kernel($F, K)
    end
end

"""

```julia
reverse(B::LocalFilters.Neighborhood)
```

yields neighborhood `B` reversed along all its dimensions.  This can be used
to correlate by `B` rather than convolving by `B`.

"""
reverse(box::RectangularBox) =
    RectangularBox(-finalindex(box), -initialindex(box))

function reverse(ker::Kernel{T,N}) where {T,N}
    kmin = -finalindex(ker)
    kmax = -initialindex(ker)
    rev = Kernel(Array{T}(undef, size(ker)), kmin)
    @inbounds for k in cartesianregion(kmin, kmax)
        rev[k] = ker[-k]
    end
    return rev
end

function strictfloor(::Type{T}, x)::T where {T}
    n = floor(T, x)
    return (n < x ? n : n - one(T))
end

"""
```julia
LocalFilters.ball(N, r)
```

yields a boolean mask which is a `N`-dimensional array with all dimensions odd
and equal and set to true where position is inside a `N`-dimesional ball of
radius `r`.

"""
function ball(rank::Integer, radius::Real)
    b = radius + 1/2
    r = strictfloor(Int, b)
    dim = 2*r + 1
    dims = ntuple(d->dim, rank)
    arr = Array{Bool}(undef, dims)
    qmax = strictfloor(Int, b^2)
    _ball!(arr, 0, qmax, r, 1:dim, tail(dims))
    return arr
end

@inline function _ball!(arr::AbstractArray{Bool,N},
                        q::Int, qmax::Int, r::Int,
                        range::AbstractUnitRange{Int},
                        dims::Tuple{Int}, I::Int...) where {N}
    nextdims = tail(dims)
    x = -r
    for i in range
        _ball!(arr, q + x*x, qmax, r, range, nextdims, I..., i)
        x += 1
    end
end

@inline function _ball!(arr::AbstractArray{Bool,N},
                        q::Int, qmax::Int, r::Int,
                        range::AbstractUnitRange{Int},
                        ::Tuple{}, I::Int...) where {N}
    x = -r
    for i in range
        arr[I...,i] = (q + x*x ≤ qmax)
        x += 1
    end
end


# Manage to automatically convert the kernel type for some operations.
convertkernel(::Type{T}, B::Kernel{<:Real,N}) where {T<:AbstractFloat,N} =
    convert(Kernel{T,N}, B)
convertkernel(::Type{T}, B::Kernel{<:Integer,N}) where {T<:Integer,N} =
    convert(Kernel{T,N}, B)
convertkernel(::Type{T}, B::Kernel{K,N}) where {T,K,N} =
    throw(ArgumentError("cannot convert kernel of type $K into type $T"))

for f in (:localmean!, :convolve!)
    @eval begin
        function $f(dst::AbstractArray{T,N},
                    A::AbstractArray{T,N},
                    B::Kernel{K,N}) where {T,K,N}
            $f(dst, A, convertkernel(T, B))
        end
    end
end

for f in (:erode!, :dilate!)
    @eval begin
        function $f(dst::AbstractArray{T,N},
                    A::AbstractArray{T,N},
                    B::Kernel{K,N}) where {T,K,N}
            $f(dst, A, convertkernel(T, B))
        end
    end
end

function localextrema!(Amin::AbstractArray{T,N},
                       Amax::AbstractArray{T,N},
                       A::AbstractArray{T,N},
                       B::Kernel{K,N}) where {T,K,N}
    localextrema!(Amin, Amax, A, convertkernel(T, B))
end
