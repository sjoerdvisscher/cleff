module Cleff.Writer where

import           Cleff
import           Cleff.Internal.Base (thisIsPureTrustMe)
import           Data.Foldable       (traverse_)
import           Data.Typeable       (Typeable)
import           UnliftIO.IORef
import           UnliftIO.MVar
import           UnliftIO.STM

data Writer w :: Effect where
  Tell :: w -> Writer w m ()
  Listen :: m a -> Writer w m (a, w)
makeEffect ''Writer

listens :: Writer w :> es => (w -> x) -> Eff es a -> Eff es (a, x)
listens f m = do
  (a, w) <- listen m
  pure (a, f w)

runLocalWriter :: forall w es a. (Typeable w, Monoid w) => Eff (Writer w ': es) a -> Eff es (a, w)
runLocalWriter m = thisIsPureTrustMe do
  rw <- newIORef mempty
  x <- reinterpret (h [rw]) m
  w' <- readIORef rw
  pure (x, w')
  where
    h :: [IORef w] -> Handler '[IOE] es (Writer w)
    h rws = \case
      Tell w' -> traverse_ (\rw -> modifyIORef' rw (<> w')) rws
      Listen (m' :: Eff es'' a') -> do
        rw' <- newIORef mempty
        x <- reinterpret (h $ rw' : rws) $ runHere m'
        w' <- readIORef rw'
        pure (x, w')
{-# INLINE runLocalWriter #-}

runAtomicLocalWriter :: forall w es a. (Typeable w, Monoid w) => Eff (Writer w ': es) a -> Eff es (a, w)
runAtomicLocalWriter m = thisIsPureTrustMe do
  rw <- newIORef mempty
  x <- reinterpret (h [rw]) m
  w' <- readIORef rw
  pure (x, w')
  where
    h :: [IORef w] -> Handler '[IOE] es (Writer w)
    h rws = \case
      Tell w' -> traverse_ (\rw -> atomicModifyIORef' rw ((, ()) . (<> w'))) rws
      Listen m' -> do
        rw' <- newIORef mempty
        x <- reinterpret (h $ rw' : rws) $ runHere m'
        w' <- readIORef rw'
        pure (x, w')
{-# INLINE runAtomicLocalWriter #-}

runSharedWriter :: forall w es a. (Typeable w, Monoid w) => Eff (Writer w ': es) a -> Eff es (a, w)
runSharedWriter m = thisIsPureTrustMe do
  rw <- newMVar mempty
  x <- reinterpret (h [rw]) m
  w' <- readMVar rw
  pure (x, w')
  where
    h :: [MVar w] -> Handler '[IOE] es (Writer w)
    h rws = \case
      Tell w' -> traverse_ (\rw -> modifyMVar_ rw \w'' -> pure $! (w'' <> w')) rws
      Listen m' -> do
        rw' <- newMVar mempty
        x <- reinterpret (h $ rw' : rws) $ runHere m'
        w' <- readMVar rw'
        pure (x, w')
{-# INLINE runSharedWriter #-}

runAtomicSharedWriter :: forall w es a. (Typeable w, Monoid w, IOE :> es) => Eff (Writer w ': es) a -> Eff es (a, w)
runAtomicSharedWriter m = do
  rw <- newTVarIO mempty
  x <- interpret (h [rw]) m
  w' <- readTVarIO rw
  pure (x, w')
  where
    h :: [TVar w] -> Interpreter es (Writer w)
    h rws = \case
      Tell w' -> atomically $ traverse_ (\rw -> modifyTVar rw (<> w')) rws
      Listen m' -> do
        rw' <- newTVarIO mempty
        x <- interpret (h $ rw' : rws) $ runHere m'
        w' <- readTVarIO rw'
        pure (x, w')
{-# INLINE runAtomicSharedWriter #-}