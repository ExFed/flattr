module Flattr where

import Data.Aeson (Value (..))
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import Data.Bifunctor (first)
import qualified Data.Vector as V
import Types (Path, Segment (..))

-- | Recursively flatten a JSON value into a list of (Path, Value) pairs.
flattenValue :: Value -> [(Path, Value)]
flattenValue val = case val of
  -- primitives
  String s -> [([], String s)]
  Number n -> [([], Number n)]
  Bool b -> [([], Bool b)]
  Null -> [([], Null)]
  -- retain empty structures
  Object o | KM.null o -> [([], Object o)]
  Array a | V.null a -> [([], Array a)]
  -- recurse into non-empty structures
  Object o ->
    let kvs = map (first K.toText) $ KM.toList o
        pathCons k (p, v) = (ObjectKey k : p, v)
     in kvs >>= \(k, v) -> map (pathCons k) $ flattenValue v
  Array a ->
    let enums = zip [0 ..] $ V.toList a
        pathCons i (p, v) = (ArrayIndex i : p, v)
     in enums >>= \(i, v) -> map (pathCons i) $ flattenValue v

unflattenAttrs :: [(Path, Value)] -> Either String Value
unflattenAttrs _attrs = error "TODO"
