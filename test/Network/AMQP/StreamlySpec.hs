{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module Network.AMQP.StreamlySpec
  ( main,
    spec,
  )
where

import Control.Concurrent (threadDelay)
import Control.Monad.IO.Class (liftIO)
import qualified Data.ByteString.Lazy.Char8 as B
import Data.Maybe (fromJust)
import qualified Data.Text as T
import Network.AMQP
import Network.AMQP.Streamly
import qualified Streamly.Data.Fold as Fold
import qualified Streamly.Data.Stream as S
import System.Process (readProcess)
import Test.Hspec
import qualified TestContainers.Docker as D
import TestContainers.Hspec

main :: IO ()
main = hspec spec

spec :: Spec
spec =
  around (withContainers containers) $
    it "producing 5 messages should be consumed in the right order" $
      \channel -> flip shouldReturn messages $ do
        let arbitraryExchange = "arbitraryExchange"
        let arbitraryRoutingKey = "arbitraryRoutingKey"
        let arbitraryQueue = "arbitraryQueue"
        let fixedInstructions =
              SendInstructions arbitraryExchange arbitraryRoutingKey True
        liftIO $
          declareExchange
            channel
            newExchange
              { exchangeName = arbitraryExchange,
                exchangeType = "fanout"
              }
        liftIO $ declareQueue channel newQueue {queueName = arbitraryQueue}
        liftIO $
          bindQueue
            channel
            arbitraryQueue
            arbitraryExchange
            arbitraryRoutingKey
        S.fold Fold.drain $ produce channel $ S.fromList $ map fixedInstructions messages
        S.toList
          ( S.take (length messages) $
              fst
                <$> consume channel arbitraryQueue NoAck
          )

messages :: [Message]
messages = map toMessage ["Lorem", "ipsum", "dolor", "sit", "amet"]
  where
    toMessage x =
      Message
        (B.pack x)
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing

mkChannel :: T.Text -> T.Text -> String -> IO Channel
mkChannel login password ip = do
  connection <- openConnection ip "/" login password
  openChannel connection

getIp :: D.Container -> IO String
getIp c =
  format
    <$> readProcess
      "docker"
      [ "inspect",
        "-f",
        "'{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'",
        T.unpack $ D.containerId c
      ]
      ""
  where
    format = init . init . tail

containers :: (MonadDocker m) => m Channel
containers = do
  let (login, password) = ("guest", "guest")
  container <- run (containerRequest $ fromTag "rabbitmq:3.8.4")
  liftIO $ threadDelay $ 15 * 1000 * 1000
  ip <- liftIO $ getIp container
  liftIO $ mkChannel login password ip
