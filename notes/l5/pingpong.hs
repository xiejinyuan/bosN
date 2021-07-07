
module Main where

import Prelude hiding (catch)
import Control.Concurrent
import Control.Exception
import Control.Monad
import Criterion.Main

pingpong :: Bool -> Int -> IO ()
pingpong v n = do
  mvc <- newEmptyMVar
  mvp <- newEmptyMVar
  let parent n | n > 0 = do when v $ putStr $ " " ++ show n
                            putMVar mvc n
                            takeMVar mvp >>= parent
             | otherwise = return ()
      child = do n <- takeMVar mvc
                 putMVar mvp (n - 1)
                 child
  tid <- forkIO child
  parent n `finally` killThread tid
  when v $ putStrLn ""

wrap :: IO a -> IO a
wrap action = do
  mv <- newEmptyMVar
  _ <- forkIO $ (action >>= putMVar mv) `catch`
       \e@(SomeException _) -> putMVar mv (throw e)
  takeMVar mv

main :: IO ()
main = defaultMain [
        bench "thread switch test" mybench
       ]
    where mybench = wrap $ pingpong False 10000
