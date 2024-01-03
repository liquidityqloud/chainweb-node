{-# LANGUAGE RecordWildCards #-}

module Chainweb.Pact.Conversions where

import Data.Coerce (coerce)

import Pact.Interpreter (PactDbEnv)
import qualified Pact.JSON.Encode as J
import qualified Pact.JSON.Legacy.HashMap as LHM
import Pact.Parse (ParsedDecimal)
import Pact.Types.ChainId (NetworkId)
import Pact.Types.ChainMeta
import Pact.Types.Command
import Pact.Types.Gas
import Pact.Types.Names
import Pact.Types.Persistence (ExecutionMode, TxLogJson)
import Pact.Types.Pretty (viaShow)
import Pact.Types.Runtime (ExecutionConfig(..), ModuleData(..), PactWarning, PactError(..), PactErrorType(..))
import Pact.Types.SPV
import Pact.Types.Term
import qualified Pact.Types.Logger as P

import qualified Pact.Core.Evaluate as PCore
import qualified Pact.Core.Compile as PCore
import qualified Pact.Core.Capabilities as PCore
import qualified Pact.Core.Info as PCore
import qualified Pact.Core.Names as PCore
import qualified Pact.Core.Namespace as PCore
import qualified Pact.Core.Persistence as PCore
import qualified Pact.Core.Pretty as PCore
import qualified Pact.Core.Gas as PCore
import qualified Pact.Core.Hash as PCore
import qualified Pact.Core.Errors as PCore
import qualified Pact.Core.Debug as PCore
import qualified Pact.Core.Serialise.LegacyPact as PCore
import qualified Pact.Core.PactValue as PCore
import qualified Pact.Core.Environment as PCore
import qualified Pact.Core.IR.Term as PCore
import qualified Pact.Core.Builtin as PCore
import qualified Pact.Core.Syntax.ParseTree as PCore
import qualified Pact.Core.DefPacts.Types as PCore
import qualified Pact.Core.Scheme as PCore

convertModuleName :: ModuleName -> PCore.ModuleName
convertModuleName ModuleName{..} =
  PCore.ModuleName
    { PCore._mnName = _mnName
    , PCore._mnNamespace = fmap coerce _mnNamespace
    }

