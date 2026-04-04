module ValueBuilderTests where

import Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import Data.Either (isLeft)
import qualified Data.Map as M
import Data.Maybe (fromJust)
import Flattr
import qualified Path
import Test.HUnit
import Types (Segment (..), ValueBuilder (..))
import ValueBuilder

fromValueTest = TestCase $ do
    let Just input = decode "{\"c\": [22, 11], \"b\": false, \"a\": null}" :: Maybe Value
    let expect =
            Obj
                ( KM.fromList
                    [ ("a", Val Null)
                    , ("b", Val $ Bool False)
                    , ("c", Arr $ M.fromList [(0, Val (Number 22)), (1, Val (Number 11))])
                    ]
                )
    let actual = fromValue input
    expect @=? actual

toValueTest = TestCase $ do
    let input =
            Obj
                ( KM.fromList
                    [ ("a", Val Null)
                    , ("b", Val $ Bool False)
                    , ("c", Arr $ M.fromList [(0, Val (Number 22)), (1, Val (Number 11))])
                    ]
                )
    let Just expect = decode "{\"c\": [22, 11], \"b\": false, \"a\": null}" :: Maybe Value
    let actual = toValue input
    expect @=? actual

toValuePaddingTest = TestCase $ do
    let input = Arr $ M.fromList [(0, Val (Number 1)), (5, Val (Number 2))]
    let Just expect = decode "[1, null, null, null, null, 2]"
    let actual = toValue input
    expect @=? actual

singletonTest = TestCase $ do
    let expect = fromValue <$> (decode "[{\"a\": {\"b\": 1}}]" :: Maybe Value)
    let actual = Just $ singleton [ArrayIndex 0, ObjectKey "a", ObjectKey "b"] (Val $ Number 1)
    expect @=? actual

mergeObjectsTest = TestCase $ do
    let Just obj1 = fromValue <$> (decode "{\"a\": 1}" :: Maybe Value)
    let Just obj2 = fromValue <$> (decode "{\"b\": 2}" :: Maybe Value)
    let Just expect = fromValue <$> (decode "{\"a\": 1, \"b\": 2}" :: Maybe Value)
    let actual = merge obj1 obj2
    -- `merge` returns an Either, so we compare Right expect with actual
    Right expect @=? actual

mergeArraysTest = TestCase $ do
    let arr1 = Arr $ M.fromList [(1, Val (Number 11))]
    let arr2 = Arr $ M.fromList [(0, Val (Number 22))]
    let Just expect = fromValue <$> (decode "[22, 11]" :: Maybe Value)
    let actual = merge arr1 arr2
    Right expect @=? actual

mergeConflictTest = TestCase $ do
    let Just val1 = fromValue <$> (decode "{\"a\": 1}" :: Maybe Value)
    let Just val2 = fromValue <$> (decode "{\"a\": {\"b\": 2}}" :: Maybe Value)
    let actual = merge val1 val2
    assertBool "Expected merge conflict (Left)" (isLeft actual)

fromRight :: (Show e) => Either e a -> Maybe a
fromRight = either (error . ("Left: " ++) . show) Just

insertInTest = TestCase $ do
    let Right p0 = Path.decode "/a$1/b"
    let v0 = Number 42
    let Just e0 = decode "{\"a\": [null, {\"b\": 42}]}" :: Maybe Value
    let Right p1 = Path.decode "/a$0/c"
    let Just e1 = decode "{\"a\": [{\"c\": \"z\"}, {\"b\": 42}]}" :: Maybe Value
    let v1 = String "z"
    let Right p2 = Path.decode "/a$2"
    let Just e2 = decode "{\"a\": [{\"c\": \"z\"}, {\"b\": 42}, 99]}" :: Maybe Value
    let v2 = Number 99
    let Right a0 = insertAt p0 v0 Nothing
    let Right a1 = insertAt p1 v1 $ Just a0
    let Right a2 = insertAt p2 v2 $ Just a1
    e0 @=? toValue a0
    e1 @=? toValue a1
    e2 @=? toValue a2

tests =
    TestList
        [ "from value" ~: fromValueTest
        , "to value" ~: toValueTest
        , "to value with padding" ~: toValuePaddingTest
        , "singleton" ~: singletonTest
        , "merge objects" ~: mergeObjectsTest
        , "merge arrays" ~: mergeArraysTest
        , "merge conflict" ~: mergeConflictTest
        , "insert in test" ~: insertInTest
        ]
