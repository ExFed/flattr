{-# LANGUAGE TupleSections #-}

module ValueBuilder (
  emptyArr,
  emptyObj,
  ensureSize,
  fromValue,
  insertAt,
  insertFilled,
  toValue,
) where

import Data.Aeson (Value (Array, Object))
import qualified Data.Aeson.Key as K
import qualified Data.Aeson.KeyMap as KM
import Data.Bifunctor (second)
import qualified Data.IntMap as IM
import qualified Data.Vector as V
import Path (toString)
import Types

fromValue :: Value -> ValueBuilder
fromValue v = case v of
  Object o -> Obj $ foldl f KM.empty (KM.toList o)
   where
    f acc (k', v') = KM.insert k' (fromValue v') acc
  Array a -> Arr $ V.ifoldl f IM.empty a
   where
    f acc i' v' = IM.insert i' (fromValue v') acc
  _ -> Val v

toValue :: ValueBuilder -> Result Value
toValue valBld = case valBld of
  Obj o -> Object . KM.fromList <$> traverse visit (KM.toList o)
   where
    visit (k, vb) = (k,) <$> toValue vb
  Arr a -> case scanGaps $ IM.toAscList a of
    Right elems -> Array . V.fromList <$> traverse toValue elems
    Left gaps -> Left $ "found gaps: " ++ show gaps
  Val v -> Right v

scanGaps :: [(Int, a)] -> Either [Int] [a]
scanGaps l = scanGaps' l (-1) [] []
 where
  scanGaps' :: [(Int, a)] -> Int -> [Int] -> [a] -> Either [Int] [a]
  scanGaps' [] _ gaps vals
    | null gaps = Right $ reverse vals
    | otherwise = Left $ reverse gaps
  scanGaps' ((i, v) : ivs) lastIdx gaps vals = case [(lastIdx + 1) .. (i - 1)] of
    [] -> scanGaps' ivs i gaps $ v : vals
    gap -> scanGaps' ivs i (reverse gap ++ gaps) $ v : vals

emptyObj :: ValueBuilder
emptyObj = Obj KM.empty

emptyArr :: ValueBuilder
emptyArr = Arr IM.empty

insertAt :: Path -> Value -> Maybe ValueBuilder -> Result ValueBuilder
insertAt = insertAt' []
 where
  insertAt' ::
    [Segment] -> [Segment] -> Value -> Maybe ValueBuilder -> Either [Char] ValueBuilder
  insertAt' crumbs path val vb' = case path of
    [] -> case vb' of
      Nothing -> Right $ Val val
      _ -> Left $ toString (reverse crumbs) ++ ": path conflict (would overwrite value)"
    (ObjectKey k) : p -> case vb' of
      Nothing -> insertAt' crumbs path val (Just (Obj KM.empty))
      Just (Obj o) -> do
        let key = K.fromText k
        inner <- insertAt' (ObjectKey k : crumbs) p val (KM.lookup key o)
        Right $ Obj $ KM.insert key inner o
      _ -> Left $ toString (reverse crumbs) ++ ": cannot traverse into non-object"
    (ArrayIndex i) : p -> case vb' of
      Nothing -> insertAt' crumbs path val (Just (Arr IM.empty))
      Just (Arr a) -> do
        inner <- insertAt' (ArrayIndex i : crumbs) p val (IM.lookup i a)
        Right $ Arr $ IM.insert i inner a
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
