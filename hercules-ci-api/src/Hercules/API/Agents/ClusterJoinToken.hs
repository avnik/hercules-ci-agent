{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}

module Hercules.API.Agents.ClusterJoinToken where

import Data.OpenApi qualified as O3
import Hercules.API.Accounts.Account (Account)
import Hercules.API.Prelude

data ClusterJoinToken = ClusterJoinToken
  { id :: Id ClusterJoinToken,
    ownerId :: Id Account,
    creationTime :: UTCTime,
    -- TODO lastAccessTime :: Maybe UTCTime
    description :: Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
