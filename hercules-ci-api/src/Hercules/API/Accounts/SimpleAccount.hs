{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}

module Hercules.API.Accounts.SimpleAccount where

import Data.OpenApi qualified as O3
import Hercules.API.Accounts.Account (Account, AccountType)
import Hercules.API.Forge.SimpleForge (SimpleForge)
import Hercules.API.Prelude

data SimpleAccount = SimpleAccount
  { id :: Id Account,
    name :: Name Account,
    displayName :: Text,
    typ :: AccountType,
    imageURL :: Text,
    site :: SimpleForge
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
