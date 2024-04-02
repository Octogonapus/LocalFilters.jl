#
# LocalFilters.jl --
#
# Local filters for Julia arrays.
#
#------------------------------------------------------------------------------
#
# This file is part of the `LocalFilters.jl` package licensed under the MIT
# "Expat" License.
#
# Copyright (c) 2017-2024, Éric Thiébaut.
#

module LocalFilters

export
    # Index ordering in filters.
    ForwardFilter,
    ReverseFilter,

    # Shift-invariant linear filters.
    correlate, correlate!,
    convolve, convolve!,
    localmean, localmean!,

    # Mathematical morphology.
    erode, erode!,
    dilate, dilate!,
    localextrema, localextrema!,
    closing, closing!,
    opening, opening!,
    bottom_hat,
    top_hat,

    # Other non-linear filters.
    bilateralfilter, bilateralfilter!,

    # Kernels and neighborhoods.
    kernel,
    reverse_kernel,

    # Generic filters.
    localfilter, localfilter!,
    strel

using OffsetArrays, StructuredArrays, EasyRanges, TypeUtils
using EasyRanges: ranges, to_int
using Base: @propagate_inbounds, tail, OneTo

function bilateralfilter end
function bilateralfilter! end

include("types.jl")
include("utils.jl")
include("generic.jl")
include("linear.jl")
include("morphology.jl")
include("bilateral.jl")
include("separable.jl")

end
