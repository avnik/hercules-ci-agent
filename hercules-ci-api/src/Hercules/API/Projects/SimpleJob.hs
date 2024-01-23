{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}

module Hercules.API.Projects.SimpleJob where

import Data.OpenApi qualified as O3
import Hercules.API.Prelude
import Hercules.API.Projects.SimpleProject (SimpleProject)

data SimpleJob = SimpleJob
  { id :: Id "Job",
    project :: SimpleProject,
    index :: Int64,
    status :: JobStatus,
    phase :: JobPhase
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data JobPhase
  = Queued
  | Evaluating
  | Building
  | Effects
  | Done
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data JobStatus
  = Pending
  | Failure
  | Success
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

-- | Whichever is "worse": 'Failure' wins out, otherwise 'Pending' wins out, otherwise all are 'Success'.
instance Semigroup JobStatus where
  Failure <> _ = Failure
  _ <> Failure = Failure
  Pending <> _ = Pending
  _ <> Pending = Pending
  Success <> Success = Success

-- | @mappend@: Whichever is "worse": 'Failure' wins out, otherwise 'Pending' wins out, otherwise all are 'Success'.
--
-- @mempty@: 'Success'
instance Monoid JobStatus where
  mappend = (<>)

  mempty = Success
