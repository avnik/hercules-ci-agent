{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}

module Hercules.API.Forge.SimpleForge where

import Data.OpenApi qualified as O3
import Hercules.API.Forge.Forge (Forge)
import Hercules.API.Prelude

data SimpleForge = SimpleForge
  { id :: Id Forge,
    name :: Name Forge,
    displayName :: Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
