module FlattrTests where

import Data.Aeson
import Data.Either (isLeft)
import Flattr (merge, singleton, unflattenAttrs)
import Test.HUnit
import Types (Segment (..))

singletonTest = TestCase $ do
  let expect = decode "{\"a\": {\"b\": 1}}" :: Maybe Value
  let actual = Just $ singleton [ObjectKey "a", ObjectKey "b"] (Number 1)
  expect @=? actual

mergeObjectsTest = TestCase $ do
  let Just obj1 = decode "{\"a\": 1}" :: Maybe Value
  let Just obj2 = decode "{\"b\": 2}" :: Maybe Value
  let expect = decode "{\"a\": 1, \"b\": 2}" :: Maybe Value
  let actual = merge obj1 obj2
  -- `merge` returns an Either, so we compare Right expect with actual
  Right (fromJust expect) @=? actual
 where
  fromJust (Just x) = x
  fromJust Nothing = error "Test setup failed"

mergeArraysTest = TestCase $ do
  let Just arr1 = decode "[1, null]" :: Maybe Value
  let Just arr2 = decode "[null, 2]" :: Maybe Value
  let expect = decode "[1, 2]" :: Maybe Value
  let actual = merge arr1 arr2
  Right (fromJust expect) @=? actual
 where
  fromJust (Just x) = x
  fromJust Nothing = error "Test setup failed"

mergeConflictTest = TestCase $ do
  let Just val1 = decode "{\"a\": 1}" :: Maybe Value
  let Just val2 = decode "{\"a\": {\"b\": 2}}" :: Maybe Value
  let actual = merge val1 val2
  assertBool "Expected merge conflict (Left)" (isLeft actual)

unflattenTest = TestCase $ do
  let input =
        [ ([ObjectKey "a", ObjectKey "b"], Number 1)
        , ([ObjectKey "a", ObjectKey "c"], Number 2)
        ]
  let expect = decode "{\"a\": {\"b\": 1, \"c\": 2}}" :: Maybe Value
  let actual = unflattenAttrs input
  Right (fromJust expect) @=? actual
 where
  fromJust (Just x) = x
  fromJust Nothing = error "Test setup failed"

tests =
  TestList
    [ "singleton" ~: singletonTest
    , "merge objects" ~: mergeObjectsTest
    , "merge arrays" ~: mergeArraysTest
    , "merge conflict" ~: mergeConflictTest
    , "unflatten" ~: unflattenTest
    ]
