module FlattrTests where

import Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import Data.Either (isLeft)
import qualified Data.Map as M
import Data.Maybe (fromJust)
import Flattr
import Test.HUnit
import Types (Segment (..), ValueBuilder (..))

flattenTest = TestCase $ do
  let Just input = decode "{ \"a\": \"b\", \"c\": [1, 2] }" :: Maybe Value
  let expect =
        [ ([ObjectKey "a"], String "b")
        , ([ObjectKey "c", ArrayIndex 0], Number 1)
        , ([ObjectKey "c", ArrayIndex 1], Number 2)
        ]
  let actual = flattenValue input
  expect @=? actual

unflattenTest = TestCase $ do
  let input =
        [ ([ObjectKey "a", ObjectKey "b"], Number 1)
        , ([ObjectKey "a", ObjectKey "c"], Number 2)
        ]
  let Just expect = decode "{\"a\": {\"b\": 1, \"c\": 2}}" :: Maybe Value
  let actual = unflattenAttrs input
  Right expect @=? actual
 where
  fromJust (Just x) = x
  fromJust Nothing = error "Test setup failed"

tests =
  TestList
    [ "flatten" ~: flattenTest
    , "unflatten" ~: unflattenTest
    ]
