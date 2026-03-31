module Path (escape, unescape, encode, decode) where

import Data.Function ((&))
import Data.Text (Text, pack, replace)
import qualified Data.Text as T
import Text.Read (readEither)
import Types (Path, Segment (..))

escape :: Text -> Text
escape t = t & replace "~" "~~" & replace "$" "~$" & replace "/" "~/"

unescape :: Text -> Text
unescape t = t & replace "~/" "/" & replace "~$" "$" & replace "~~" "~"

encode :: Path -> Text
encode [] = ""
encode ((ObjectKey k) : es) = "/" <> escape k <> encode es
encode ((ArrayIndex i) : es) = "$" <> pack (show i) <> encode es

decode :: Text -> Either String Path
decode = parsePath
 where
  -- Recursively parse the path segments
  parsePath :: Text -> Either String Path
  parsePath t = case T.uncons t of
    -- end of path
    Nothing -> Right []
    -- object key
    Just ('/', rest) -> do
      (token, rest') <- nextToken "" rest
      (ObjectKey (pack token) :) <$> parsePath rest'
    -- array index
    Just ('$', rest) -> do
      (token, rest') <- nextToken "" rest
      idx <- readEither token
      (ArrayIndex idx :) <$> parsePath rest'
    -- errors
    Just (c, _) -> Left $ "Expected '/' or '$' but got: " ++ [c]

  -- Consume characters until the next unescaped '/' or '$', unescaping as we go
  nextToken :: String -> Text -> Either String (String, Text)
  nextToken acc t = case T.uncons t of
    -- complete token
    Nothing -> Right (reverse acc, t)
    Just ('/', _) -> Right (reverse acc, t)
    Just ('$', _) -> Right (reverse acc, t)
    -- escape sequences
    Just ('~', rest) -> case T.uncons rest of -- lookahead
      Just ('/', rest') -> nextToken ('/' : acc) rest'
      Just ('$', rest') -> nextToken ('$' : acc) rest'
      Just ('~', rest') -> nextToken ('~' : acc) rest'
      -- errors
      Just (c, _) -> Left $ "Invalid escape: ~" ++ [c]
      Nothing -> Left "Invalid escape: ~"
    -- continue scanning
    Just (c, rest) -> nextToken (c : acc) rest
