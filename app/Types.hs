module Types where

import Data.Text (Text)

data Segment
  = ObjectKey Text
  | ArrayIndex Int
  deriving (Show, Eq)

type Path = [Segment]
