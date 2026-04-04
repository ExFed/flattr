module Main (main) where

import System.Exit (exitFailure, exitSuccess)
import Test.HUnit

import qualified FlattrTests
import qualified ValueBuilderTests

main :: IO ()
main = do
  counts <- runTestTT tests
  if errors counts == 0 && failures counts == 0
    then exitSuccess
    else exitFailure

tests =
  TestList
    [ "Flattr" ~: FlattrTests.tests
    , "ValueBuilder" ~: ValueBuilderTests.tests
    ]
