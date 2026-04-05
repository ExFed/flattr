{-# LANGUAGE InstanceSigs #-}

module Types where

import Data.Aeson (Value (..))
import qualified Data.Aeson.KeyMap as KM
import qualified Data.IntMap as IM
import Data.Text (Text, unpack)

data Segment
  = ObjectKey Text
  | ArrayIndex Int
  deriving (Eq)

instance Show Segment where
  show :: Segment -> String
  show (ObjectKey k) = "/" ++ unpack k
  show (ArrayIndex i) = "$" ++ show i

type Path = [Segment]

type Result a = Either String a

data ValueBuilder
  = Obj (KM.KeyMap ValueBuilder)
  | Arr (IM.IntMap ValueBuilder)
  | Val Value
  deriving (Show, Eq)
