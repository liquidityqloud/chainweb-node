{-# LANGUAGE RankNTypes #-}

module Chainweb.Test.Pact.RewardsTest
  ( tests,
  )
where

import Chainweb.Graph
import Chainweb.Miner.Pact
import Chainweb.Pact.PactService.ExecBlock
import Chainweb.Test.Utils
import Chainweb.Version
import Pact.Parse
import Test.Tasty
import Test.Tasty.HUnit

v :: ChainwebVersion
v = FastTimedCPM petersonChainGraph

tests :: ScheduledTest
tests =
  ScheduledTest "Chainweb.Test.Pact.RewardsTest" $
    testGroup
      "Miner Rewards Unit Tests"
      [ rewardsTest
      ]

rewardsTest :: HasCallStack => TestTree
rewardsTest = testCaseSteps "rewards" $ \step -> do
  let rs = readRewards
      k = minerReward v rs

  step "block heights below initial threshold"
  ParsedDecimal a <- k 0
  assertEqual "initial miner reward is 2.304523" 2.304523 a

  step "block heights at threshold"
  ParsedDecimal b <- k 87600
  assertEqual "max threshold miner reward is 2.304523" 2.304523 b

  step "block heights exceeding thresholds change"
  ParsedDecimal c <- k 87601
  assertEqual "max threshold miner reward is 2.297878" 2.297878 c
