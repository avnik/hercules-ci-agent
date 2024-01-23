{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}

module Hercules.API.State.StateVersion where

import Data.OpenApi qualified as O3
import Hercules.API.Accounts.Account (Account)
import Hercules.API.Prelude
import Hercules.API.Projects.Job (Job)
import Hercules.API.Projects.Project (Project)

data StateVersion = StateVersion
  { projectId :: Id Project,
    name :: Text,
    version :: Int,
    creationTime :: UTCTime,
    -- jobId :: Maybe (Id Job),
    job :: Maybe Job,
    -- effectEventId :: Maybe (Id "EffectEvent"),
    --  agentId :: Maybe (Id AgentSession),
    uploader :: Maybe Account,
    sha256 :: Maybe Text,
    size :: Maybe Int
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
