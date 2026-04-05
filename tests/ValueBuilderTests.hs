module ValueBuilderTests where

import Data.Aeson
import qualified Data.Aeson.KeyMap as KM
import Data.Either (isLeft)
import qualified Data.IntMap.Strict as IM
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
                    , ("c", Arr $ IM.fromList [(0, Val (Number 22)), (1, Val (Number 11))])
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
                    , ("c", Arr $ IM.fromList [(0, Val (Number 22)), (1, Val (Number 11))])
                    ]
                )
    let Just expect = decode "{\"c\": [22, 11], \"b\": false, \"a\": null}" :: Maybe Value
    let actual = toValue input
    expect @=? actual

toValuePaddingTest = TestCase $ do
    let input = Arr $ IM.fromList [(0, Val (Number 1)), (5, Val (Number 2))]
    let Just expect = decode "[1, null, null, null, null, 2]"
    let actual = toValue input
    expect @=? actual

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
        , "insert in test" ~: insertInTest
        ]
