module Flattr (flattenValue, flattr, unflattenAttrs, unflattr) where

import Control.Monad (foldM)
import Data.Aeson (Value (..))
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import Data.Bifunctor (first)
import qualified Data.Vector as V
import qualified Path as P
import Types (Path, Segment (..))
import qualified ValueBuilder as VB

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
unflattenAttrs attrs = do
  vb <- foldM (\acc (p, v) -> Just <$> VB.insertAt p v acc) Nothing attrs
  return $ maybe Null VB.toValue vb

flattr :: Value -> Value
flattr val =
  let attrs = flattenValue val
      objEntries = map (first $ K.fromText . P.encode) attrs
   in Object $ KM.fromList objEntries

unflattr :: Value -> Either String Value
unflattr val = case val of
  Object attrMap -> do
    let objEntries = KM.toList attrMap
    let visit (k, v) = case P.decode $ K.toText k of
          Right p -> Right (p, v)
          Left e -> Left e
    attrs <- traverse visit objEntries
    unflattenAttrs attrs
  _ -> Left "not an attribute object"
