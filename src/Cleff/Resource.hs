{-# OPTIONS_GHC -Wno-orphans #-}
module Cleff.Resource where

import           Cleff
import           Control.Monad.IO.Class                (liftIO)
import           Control.Monad.Trans.Resource          (InternalState,
                                                        MonadResource (liftResourceT),
                                                        createInternalState)
import           Control.Monad.Trans.Resource.Internal (ResourceT (..),
                                                        stateCleanupChecked)
import           UnliftIO.Exception

data Resource :: Effect where
  LiftResourceT :: ResourceT IO a -> Resource m a

instance (Resource :> es, IOE :> es) => MonadResource (Eff es) where
  liftResourceT = send . LiftResourceT

runResource :: forall es a. IOE :> es => Eff (Resource ': es) a -> Eff es a
runResource m = mask \restore -> do
  istate <- createInternalState
  a <- restore (interpretIO (h istate) m) `catch` \e -> do
    liftIO $ stateCleanupChecked (Just e) istate
    throwIO e
  liftIO $ stateCleanupChecked Nothing istate
  pure a
  where
    h :: InternalState -> InterpreterIO es Resource
    h istate = \case
      LiftResourceT (ResourceT m') -> m' istate
{-# INLINE runResource #-}
