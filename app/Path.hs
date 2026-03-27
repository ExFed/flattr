module Path where

import Data.Function ((&))
import Data.Text (Text, pack, replace)
import qualified Data.Text as T
import Types (Path, Segment (..))

escape :: Text -> Text
escape t = t & replace "~" "~~" & replace "$" "~$" & replace "/" "~/"

unescape :: Text -> Text
unescape t = t & replace "~/" "/" & replace "~$" "$" & replace "~~" "~"

encode :: Path -> Text
encode [] = ""
encode ((ObjectKey k) : es) = "/" <> escape k <> encode es
encode ((ArrayIndex i) : es) = "$" <> pack (show i) <> encode es

decode :: Text -> Path
decode "" = []
decode txt = path ++ seg nextSeg tnemele
  where
    (path, nextSeg, tnemele) = T.foldl nextCh ([], Nothing, "") txt
    nextCh (_, Nothing, "") '/' = ([], Just key, "") -- first token
    nextCh (_, Nothing, "") '$' = ([], Just idx, "") -- first token
    nextCh (_, Nothing, "") c = error $ "Expected '/' or '$' but got: " ++ [c] -- bad input
    nextCh (segs, nSeg, '~' : mele) '/' = (segs, nSeg, '/' : '~' : mele) -- escape
    nextCh (segs, nSeg, '~' : mele) '$' = (segs, nSeg, '$' : '~' : mele) -- escape
    nextCh (segs, nSeg, '~' : mele) '~' = (segs, nSeg, '~' : '~' : mele) -- escape
    nextCh (segs, nSeg, '~' : '~' : mele) c = (segs, nSeg, c : '~' : '~' : mele) -- special case
    nextCh (_, _, '~' : _) c = error $ "Invalid escape: ~" ++ [c] -- bad escape
    nextCh (segs, nSeg, mele) '/' = (segs ++ seg nSeg mele, Just key, "") -- flush
    nextCh (segs, nSeg, mele) '$' = (segs ++ seg nSeg mele, Just idx, "") -- flush
    nextCh (segs, nSeg, mele) c = (segs, nSeg, c : mele) -- normal char
    seg nSeg mele = case nSeg of
      Nothing -> error "Must be either a Key or Index"
      (Just segFn) -> [segFn $ unescape $ pack $ reverse mele]
    key = ObjectKey
    idx t = ArrayIndex (read $ T.unpack t :: Int)
