module Main (main) where

import qualified FlattrTests
import System.Exit (exitFailure, exitSuccess)
import Test.HUnit

main :: IO ()
main = do
  -- Run all tests
  counts <- runTestTT tests

  -- Print summary
  print counts

  if errors counts == 0 && failures counts == 0
    then exitSuccess
    else exitFailure

tests =
  TestList
    [ "Path" ~: FlattrTests.tests
    ]
