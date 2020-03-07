module Citrous.Unit.Handler
  ( Handler
  , HasRequest
  , toApplication
  , responseLBS
  , maybeJson
  , textPlain
  , textHtml
  , json
  , RequestBodyLength(..)
  , requestMethod
  , httpVersion
  , rawPathInfo
  , rawQueryString
  , requestHeaders
  , isSecure
  , remoteHost
  , pathInfo
  , queryString
  , requestBodyChunk
  , vault
  , requestBodyLength
  , requestHeaderHost
  , requestHeaderRange
  , requestHeaderReferer
  , requestHeaderUserAgent
  , getQuery
  , runHandler
  , runHandlerT
  , throwErr
  , returnResponse
  ) where

import           Citrous.Unit.Application (ToApplication (..))
import           Control.Monad            (join)
import           Control.Monad.Identity   (Identity, runIdentity)
import           Control.Monad.Reader     (Reader, ReaderT, ask, asks,
                                           runReader, runReaderT)
import           Control.Monad.Trans      (liftIO)
import           Data.Aeson               (FromJSON, ToJSON, encode)
import           Data.ByteString          (ByteString)
import           Data.Text                (Text)
import           Data.Utf8Convertible     (ConvertTo, convert)
import           Data.Vault.Lazy          (Vault)
import           Network.HTTP.Types       (HttpVersion, Method, Query,
                                           RequestHeaders, ok200)
import           Network.Socket           (SockAddr)
import           Network.Wai              (Application, Request,
                                           RequestBodyLength, Response,
                                           responseLBS)
import qualified Network.Wai              as Wai
import Citrous.Unit.ServerErr (ServerErr, responseServerError)

type HasRequestT m a = ReaderT Request m a

type HasRequest a = HasRequestT Identity a

type HandlerT m = HasRequestT m (Either ServerErr Response)

type Handler = HandlerT Identity 

instance ToApplication Handler where
  toApplication action req respond = respond $ runHandler action req

returnResponse :: Response -> Handler
returnResponse = return . Right

throwErr :: ServerErr -> Handler
throwErr = return . Left

runHandlerT :: HandlerT m -> Request -> m (Either ServerErr Response)
runHandlerT = runReaderT

runHandler :: Handler -> Request -> Response
runHandler act req = case runIdentity $ runHandlerT act req of
  Right response -> response
  Left serverErr -> responseServerError serverErr

json :: (FromJSON a, ToJSON a) => a -> Handler
json jsonData = returnResponse $ responseLBS ok200 [("Content-Type", "application/json; charset=utf-8")] (encode jsonData)

maybeJson :: (FromJSON a, ToJSON a) => Maybe a -> Handler
maybeJson jsonData =
  returnResponse $ responseLBS ok200 [("Content-Type", "application/json; charset=utf-8")] (maybe "null" encode jsonData)

textPlain :: Text -> Handler
textPlain txt = returnResponse $ responseLBS ok200 [("Content-Type", "text/plain; charset=utf-8")] (convert txt)

textHtml :: Text -> Handler
textHtml html = returnResponse $ responseLBS ok200 [("Content-Type", "text/html; charset=utf-8")] (convert html)

requestMethod :: HasRequest Method
requestMethod = asks Wai.requestMethod

httpVersion :: HasRequest HttpVersion
httpVersion = asks Wai.httpVersion

rawPathInfo :: HasRequest ByteString
rawPathInfo = asks Wai.rawPathInfo

rawQueryString :: HasRequest ByteString
rawQueryString = asks Wai.rawQueryString

requestHeaders :: HasRequest RequestHeaders
requestHeaders = asks Wai.requestHeaders

isSecure :: HasRequest Bool
isSecure = asks Wai.isSecure

remoteHost :: HasRequest SockAddr
remoteHost = asks Wai.remoteHost

pathInfo :: HasRequest [Text]
pathInfo = asks Wai.pathInfo

queryString :: HasRequest Query
queryString = asks Wai.queryString

requestBodyChunk :: HasRequest (IO ByteString)
requestBodyChunk = asks Wai.getRequestBodyChunk

vault :: HasRequest Vault
vault = asks Wai.vault

requestBodyLength :: HasRequest RequestBodyLength
requestBodyLength = asks Wai.requestBodyLength

requestHeaderHost :: HasRequest (Maybe ByteString)
requestHeaderHost = asks Wai.requestHeaderHost

requestHeaderRange :: HasRequest (Maybe ByteString)
requestHeaderRange = asks Wai.requestHeaderRange

requestHeaderReferer :: HasRequest (Maybe ByteString)
requestHeaderReferer = asks Wai.requestHeaderReferer

requestHeaderUserAgent :: HasRequest (Maybe ByteString)
requestHeaderUserAgent = asks Wai.requestHeaderUserAgent

getQuery :: ByteString -> HasRequest (Maybe ByteString)
getQuery key = join <$> (lookup key <$> queryString)
