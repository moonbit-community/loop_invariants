// Explicit `extend` declarations for trait impls that used to be
// implicitly promoted to regular methods (warning 79,
// `implicit_impl_as_method`). Promotions that are still useful in dot
// form are kept; the rest stay available for source compatibility but
// are deprecated in favour of the trait-level API.

// --- promoted: kept as regular methods ---

///|
pub extend Point with Eq::{equal}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Point with Debug::{to_repr}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Point with Eq::{not_equal}
