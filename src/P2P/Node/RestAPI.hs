{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

-- |
-- Module: P2P.Node.RestAPI
-- Copyright: Copyright © 2018 Kadena LLC.
-- License: MIT
-- Maintainer: Lars Kuhtz <lars@kadena.io>
-- Stability: experimental
--
-- REST API endpoints for the Chainweb P2P network.
module P2P.Node.RestAPI
  ( -- * P2P API
    PeerGetApi,
    peerGetApi,
    PeerPutApi,
    peerPutApi,
    P2pApi,
    p2pApi,

    -- * Some P2P API
    someP2pApi,
    someP2pApis,
  )
where

-- internal modules

import Chainweb.ChainId
import Chainweb.RestAPI.NetworkID
import Chainweb.RestAPI.Orphans ()
import Chainweb.RestAPI.Utils
import Chainweb.Utils.Paging
import Chainweb.Version
import Data.Proxy
import P2P.Peer
import Servant

-- -------------------------------------------------------------------------- --
-- @GET /chainweb/<ApiVersion>/<ChainwebVersion>/chain/<ChainId>/peer/@

type PeerGetApi_ =
  "peer"
    :> PageParams (NextItem Int)
    :> Get '[JSON] (Page (NextItem Int) PeerInfo)

type PeerGetApi (v :: ChainwebVersionT) (n :: NetworkIdT) =
  'ChainwebEndpoint v :> 'NetworkEndpoint n :> Reassoc PeerGetApi_

peerGetApi ::
  forall (v :: ChainwebVersionT) (n :: NetworkIdT).
  Proxy (PeerGetApi v n)
peerGetApi = Proxy

-- -------------------------------------------------------------------------- --
-- @PUT /chainweb/<ApiVersion>/<ChainwebVersion>/chain/<ChainId>/peer/@

type PeerPutApi_ =
  "peer"
    :> ReqBody '[JSON] PeerInfo
    :> Verb 'PUT 204 '[JSON] NoContent

type PeerPutApi (v :: ChainwebVersionT) (n :: NetworkIdT) =
  'ChainwebEndpoint v :> 'NetworkEndpoint n :> Reassoc PeerPutApi_

peerPutApi ::
  forall (v :: ChainwebVersionT) (n :: NetworkIdT).
  Proxy (PeerPutApi v n)
peerPutApi = Proxy

-- -------------------------------------------------------------------------- --
-- P2P API

type P2pApi v n =
  PeerGetApi v n
    :<|> PeerPutApi v n

p2pApi ::
  forall (v :: ChainwebVersionT) (n :: NetworkIdT).
  Proxy (P2pApi v n)
p2pApi = Proxy

-- -------------------------------------------------------------------------- --
-- Mulit Chain API

someP2pApi :: ChainwebVersion -> NetworkId -> SomeApi
someP2pApi (FromSingChainwebVersion (SChainwebVersion :: Sing v)) = f
  where
    f (FromSingNetworkId (SChainNetwork SChainId :: Sing n)) = SomeApi $ p2pApi @v @n
    f (FromSingNetworkId (SMempoolNetwork SChainId :: Sing n)) = SomeApi $ p2pApi @v @n
    f (FromSingNetworkId (SCutNetwork :: Sing n)) = SomeApi $ p2pApi @v @n

someP2pApis :: ChainwebVersion -> [NetworkId] -> SomeApi
someP2pApis v = mconcat . fmap (someP2pApi v)
