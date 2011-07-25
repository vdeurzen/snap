{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}

module Snap.Snaplet.Session 

(
    SessionManager
  , withSession
  , commitSession
  , setInSession
  , getFromSession
  , csrfToken
  , sessionToList
  , resetSession
  , touchSession

) where

import           Control.Monad.Reader
import           Control.Monad.State
import           Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B
import           Data.Record.Label
import           Data.Serialize (Serialize)
import           Data.Text (Text)

import           Snap.Snaplet
import           Snap.Snaplet.Session.SecureCookie
import           Snap.Types

import           Snap.Snaplet.Session.SessionManager 
                   ( SessionManager(..), ISessionManager(..) )
import qualified Snap.Snaplet.Session.SessionManager as SM



-- | Wrap around a handler, committing any changes in the session at the end
withSession :: (b :-> Snaplet SessionManager) -> Handler b e a -> Handler b e a
withSession l h = do
  a <- h 
  withSibling l commitSession
  return a


-- | Commit changes to session within the current request cycle 
commitSession :: Handler b SessionManager ()
commitSession = do
  mgr@(SessionManager b) <- loadSession
  liftSnap $ commit b


-- | Set a key-value pair in the current session
setInSession :: Text -> Text -> Handler b SessionManager ()
setInSession k v = do
  mgr@(SessionManager r) <- loadSession
  let r' = SM.insert k v r
  put $ SessionManager r'


-- | Get a key from the current session
getFromSession :: Text -> Handler b SessionManager (Maybe Text)
getFromSession k = do
  mgr@(SessionManager r) <- loadSession
  return $ SM.lookup k r


-- | Returns a CSRF Token unique to the current session
csrfToken :: Handler b SessionManager Text
csrfToken = do
  mgr@(SessionManager r) <- loadSession
  put mgr
  return $ SM.csrf r


-- | Return session contents as an association list
sessionToList :: Handler b SessionManager [(Text, Text)]
sessionToList = do
  mgr@(SessionManager r) <- loadSession
  return $ SM.toList r


-- | Deletes the session cookie, effectively resetting the session
resetSession :: Handler b SessionManager ()
resetSession = do
  mgr@(SessionManager r) <- loadSession
  r' <- liftSnap $ SM.reset r
  put $ SessionManager r'


-- | Touch the session so the timeout gets refreshed
touchSession :: Handler b SessionManager ()
touchSession = do
  mgr@(SessionManager r) <- loadSession
  let r' = SM.touch r
  put $ SessionManager r'


-- | Load the session into the manager
loadSession :: Handler b SessionManager SessionManager
loadSession = do
  mgr@(SessionManager r) <- get
  r' <- liftSnap $ load r 
  return $ SessionManager r'
