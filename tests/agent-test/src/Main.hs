module Main where

import MockTasksApi (withServer)
import Protolude
import Spec qualified
import System.IO
import System.Timeout (timeout)
import Test.Hspec
import Test.Hspec.Runner

main :: IO ()
main = do
  hSetBuffering stdout LineBuffering
  hSetBuffering stderr LineBuffering
  withTimeout $
    withServer $ \server ->
      hspecWith config (beforeAll (pure server) Spec.spec)
  where
    config =
      defaultConfig
        { configColorMode = ColorAlways,
          configUnicodeMode = UnicodeAlways
        }

withTimeout :: IO () -> IO ()
withTimeout =
  let oneSecond = 1000 * 1000
      minute = 60 * oneSecond
   in timeout (15 * minute) >=> \case
        Just _ -> pass
        Nothing -> do
          putText "Test suite timed out!"
          exitFailure
