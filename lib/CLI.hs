module CLI (cli) where

import Control.Exception (Exception (displayException))
import Data.Aeson (Value, eitherDecodeStrict, encode)
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import qualified Data.Yaml as Y
import Flattr (flattr, unflattr)
import System.Environment (getArgs, getProgName)
import System.Exit (die)

data Format = JSON | YAML deriving (Show, Eq)

cli :: IO ()
cli = do
  progName <- getProgName
  args <- getArgs

  format <- case args of
    ["--format", "json"] -> return JSON
    ["--format", "yaml"] -> return YAML
    _ -> die $ "Usage: " ++ progName ++ " --format [json|yaml]"

  input <- B.getContents

  output <- case progName of
    "flattr" -> runFlattr format input
    "unflattr" -> runUnflattr format input
    _ -> die "Executable must be named 'flattr' or 'unflattr'"

  BL.putStr output

runFlattr :: Format -> B.ByteString -> IO BL.ByteString
runFlattr format input = case format of
  JSON -> do
    val <- decodeJSON input
    return $ encode $ flattr val
  YAML -> do
    val <- decodeYAML input
    return $ BL.fromStrict $ Y.encode $ flattr val

runUnflattr :: Format -> B.ByteString -> IO BL.ByteString
runUnflattr format input = case format of
  JSON -> do
    val <- decodeJSON input
    case unflattr val of
      Right out -> return $ encode out
      Left e -> die $ "ERROR: " ++ e
  YAML -> do
    val <- decodeYAML input
    case unflattr val of
      Right out -> return $ BL.fromStrict $ Y.encode out
      Left e -> die $ "ERROR: " ++ e

decodeJSON :: B.ByteString -> IO Value
decodeJSON bs = case (eitherDecodeStrict bs :: Either String Value) of
  Left e -> die $ "ERROR: " ++ e
  Right val -> return val

decodeYAML :: B.ByteString -> IO Value
decodeYAML bs = case (Y.decodeEither' bs :: Either Y.ParseException Value) of
  Left e -> die $ "ERROR: " ++ displayException e
  Right val -> return val
