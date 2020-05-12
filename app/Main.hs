{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Citrous.API
import           Control.Monad.Error.Class (throwError)
import           Data.Aeson                (FromJSON, ToJSON)
import           Data.Text                 (Text)
import           GHC.Generics              (Generic)

main :: IO ()
main = do
  putStrLn $ "Listen and serve on " ++ show port
  runCitrous port routes
  where
    port :: Port
    port = 8080

routes :: Routes Handler
routes = do
  get (match "/") topAction
  get (match "/hello" </> text) helloAction
  get (match "/echoUser" </> text </> int) echoUserAction
  absolute notFount

topAction :: Handler
topAction = textPlain "Hello Citrous!!"

helloAction :: Text -> Handler
helloAction name = textPlain $ "Hello " <> name <> "!!"

echoUserAction :: Text -> Int -> Handler
echoUserAction name age = json $ User name age

notFount :: Handler
notFount = throwError err404

data User = User
    { name :: Text
    , age  :: Int
    }
    deriving (Generic, Show)
instance ToJSON User
instance FromJSON User
