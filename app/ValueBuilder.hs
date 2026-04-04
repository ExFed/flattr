module ValueBuilder (
  (>>|<<),
  emptyArr,
  emptyObj,
  ensureSize,
  fromValue,
  insertAt,
  insertFilled,
  merge,
  singleton,
  toValue,
) where

import Data.Aeson (Value (Array, Null, Object))
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import Data.Bifunctor (second)
import qualified Data.Map as M
import Data.Maybe (fromMaybe)
import qualified Data.Vector as V
import Path (toString)
import Types

fromValue :: Value -> ValueBuilder
fromValue v = case v of
  Object o -> Obj $ foldl f KM.empty (KM.toList o)
   where
    f acc (k', v') = KM.insert k' (fromValue v') acc
  Array a -> Arr $ V.ifoldl f M.empty a
   where
    f acc i' v' = M.insert i' (fromValue v') acc
  _ -> Val v

toValue :: ValueBuilder -> Value
toValue v = case v of
  Obj o -> Object $ foldl f KM.empty (KM.toList o)
   where
    f acc (k', v') = KM.insert k' (toValue v') acc
  Arr a -> Array $ fromMaybe Null <$> M.foldrWithKey f V.empty a
   where
    f :: Int -> ValueBuilder -> V.Vector (Maybe Value) -> V.Vector (Maybe Value)
    f k v' = insertFilled [(k, toValue v')]
  Val v' -> v'

emptyObj :: ValueBuilder
emptyObj = Obj KM.empty

emptyArr :: ValueBuilder
emptyArr = Arr M.empty

singleton :: Path -> ValueBuilder -> ValueBuilder
singleton [] v = v
singleton (p : ss) v = case p of
  (ObjectKey k) -> Obj $ KM.singleton (K.fromText k) (singleton ss v)
  (ArrayIndex i) -> Arr $ M.singleton i (singleton ss v)

merge :: ValueBuilder -> ValueBuilder -> Result ValueBuilder
merge (Obj a) (Obj b) =
  let a' = KM.map Right a
      b' = KM.map Right b
      ab = KM.unionWith mergeResults a' b'
   in Obj <$> sequenceA ab
merge (Arr a) (Arr b) =
  let a' = M.map Right a
      b' = M.map Right b
      ab = M.unionWith mergeResults a' b'
   in Arr <$> sequenceA ab
merge (Val a) (Val b) = Left ("Cannot merge values: (" ++ show a ++ ") >>|<< (" ++ show b ++ ")")
merge a b = Left ("Cannot merge mismatched types: (" ++ show a ++ ") >>|<< (" ++ show b ++ ")")

(>>|<<) :: Result ValueBuilder -> Result ValueBuilder -> Result ValueBuilder
(>>|<<) = mergeResults
infixl 1 >>|<<

mergeResults :: Result ValueBuilder -> Result ValueBuilder -> Result ValueBuilder
mergeResults ra rb = do
  va <- ra
  vb <- rb
  merge va vb

insertAt :: Path -> Value -> Maybe ValueBuilder -> Result ValueBuilder
insertAt = insertAt' []
 where
  insertAt' crumbs path val vb' = case path of
    [] -> Right $ Val val
    (ObjectKey k) : p -> case vb' of
      Nothing -> insertAt' crumbs path val (Just (Obj KM.empty))
      Just (Obj o) -> do
        let key = K.fromText k
        inner <- insertAt' (ObjectKey k : crumbs) p val (KM.lookup key o)
        Right $ Obj $ KM.insert key inner o
      _ -> Left $ toString (reverse crumbs) ++ ": cannot traverse into non-object"
    (ArrayIndex i) : p -> case vb' of
      Nothing -> insertAt' crumbs path val (Just (Arr M.empty))
      Just (Arr a) -> do
        inner <- insertAt' (ArrayIndex i : crumbs) p val (M.lookup i a)
        Right $ Arr $ M.insert i inner a
      _ -> Left $ toString (reverse crumbs) ++ ": cannot traverse into non-array"

ensureSize :: a -> Int -> V.Vector a -> V.Vector a
ensureSize fillVal size vec
  | V.length vec >= size = vec
  | otherwise = vec V.++ V.replicate (size - V.length vec) fillVal

insertFilled :: [(Int, a)] -> V.Vector (Maybe a) -> V.Vector (Maybe a)
insertFilled idxValPairs vec = vec' V.// fmap (second Just) idxValPairs
 where
  maxIdx = maximum $ fmap fst idxValPairs
  vec' = ensureSize Nothing (1 + maxIdx) vec
